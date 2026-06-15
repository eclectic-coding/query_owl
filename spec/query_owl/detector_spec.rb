require "rails_helper"

RSpec.describe QueryOwl::Detector do
  def query(sql, count: 1, cached: false)
    Array.new(count) { { sql: sql, cached: cached, backtrace: ["app/models/user.rb:10"] } }
  end

  describe ".detect_n_plus_one" do
    it "flags queries repeated at or above the threshold" do
      queries = query("SELECT * FROM users WHERE id = 1") +
                query("SELECT * FROM users WHERE id = 2")

      results = described_class.detect_n_plus_one(queries)

      expect(results.length).to eq(1)
      expect(results.first[:type]).to eq(:n_plus_one)
      expect(results.first[:count]).to eq(2)
    end

    it "does not flag queries below the threshold" do
      results = described_class.detect_n_plus_one(query("SELECT * FROM users WHERE id = 1"))
      expect(results).to be_empty
    end

    it "groups queries by normalized SQL" do
      queries = query("SELECT * FROM posts WHERE user_id = 1") +
                query("SELECT * FROM posts WHERE user_id = 2") +
                query("SELECT * FROM posts WHERE user_id = 3")

      results = described_class.detect_n_plus_one(queries)
      expect(results.length).to eq(1)
      expect(results.first[:count]).to eq(3)
    end

    it "does not group unrelated queries together" do
      queries = query("SELECT * FROM users WHERE id = 1") +
                query("SELECT * FROM posts WHERE id = 1")

      results = described_class.detect_n_plus_one(queries)
      expect(results).to be_empty
    end

    it "excludes cached queries" do
      queries = query("SELECT * FROM users WHERE id = 1", cached: true) +
                query("SELECT * FROM users WHERE id = 2", cached: true)

      results = described_class.detect_n_plus_one(queries)
      expect(results).to be_empty
    end

    it "includes backtrace from the first occurrence" do
      queries = query("SELECT * FROM users WHERE id = 1") +
                query("SELECT * FROM users WHERE id = 2")

      result = described_class.detect_n_plus_one(queries).first
      expect(result[:backtrace]).to eq(["app/models/user.rb:10"])
    end

    it "respects n_plus_one_threshold config" do
      QueryOwl.config.n_plus_one_threshold = 3
      queries = query("SELECT * FROM users WHERE id = 1") +
                query("SELECT * FROM users WHERE id = 2")

      expect(described_class.detect_n_plus_one(queries)).to be_empty
    ensure
      QueryOwl.reset_config!
    end
  end

  describe ".detect_slow_queries" do
    def slow_query(sql, duration_ms:, cached: false)
      { sql: sql, duration_ms: duration_ms, cached: cached, backtrace: ["app/models/post.rb:5"] }
    end

    it "flags queries exceeding the threshold" do
      results = described_class.detect_slow_queries([slow_query("SELECT * FROM posts", duration_ms: 150)])
      expect(results.length).to eq(1)
      expect(results.first[:type]).to eq(:slow_query)
      expect(results.first[:duration_ms]).to eq(150)
    end

    it "does not flag queries below the threshold" do
      results = described_class.detect_slow_queries([slow_query("SELECT * FROM posts", duration_ms: 50)])
      expect(results).to be_empty
    end

    it "flags queries at exactly the threshold" do
      results = described_class.detect_slow_queries([slow_query("SELECT 1", duration_ms: 100)])
      expect(results.length).to eq(1)
    end

    it "excludes cached queries" do
      results = described_class.detect_slow_queries([slow_query("SELECT * FROM posts", duration_ms: 500, cached: true)])
      expect(results).to be_empty
    end

    it "normalizes the SQL in the result" do
      results = described_class.detect_slow_queries([slow_query("SELECT * FROM posts WHERE id = 42", duration_ms: 200)])
      expect(results.first[:sql]).to eq("SELECT * FROM posts WHERE id = ?")
    end

    it "includes backtrace in the result" do
      results = described_class.detect_slow_queries([slow_query("SELECT 1", duration_ms: 200)])
      expect(results.first[:backtrace]).to eq(["app/models/post.rb:5"])
    end

    it "respects slow_query_threshold_ms config" do
      QueryOwl.config.slow_query_threshold_ms = 500
      results = described_class.detect_slow_queries([slow_query("SELECT 1", duration_ms: 200)])
      expect(results).to be_empty
    ensure
      QueryOwl.reset_config!
    end
  end

  describe ".detect_unused_eager_loads" do
    def eager_data(preloaded:, accessed:)
      { preloaded: preloaded, accessed: Set.new(accessed) }
    end

    it "flags an association that was preloaded but never accessed" do
      data = eager_data(
        preloaded: [{ model: "Widget", association: "tags" }],
        accessed: []
      )
      results = described_class.detect_unused_eager_loads(data)
      expect(results.length).to eq(1)
      expect(results.first[:type]).to eq(:unused_eager_load)
      expect(results.first[:model]).to eq("Widget")
      expect(results.first[:association]).to eq("tags")
    end

    it "does not flag an association that was preloaded and accessed" do
      data = eager_data(
        preloaded: [{ model: "Widget", association: "tags" }],
        accessed: ["Widget#tags"]
      )
      results = described_class.detect_unused_eager_loads(data)
      expect(results).to be_empty
    end

    it "returns empty when nothing was preloaded" do
      data = eager_data(preloaded: [], accessed: [])
      expect(described_class.detect_unused_eager_loads(data)).to be_empty
    end

    it "deduplicates preloaded entries before comparing" do
      data = eager_data(
        preloaded: [
          { model: "Widget", association: "tags" },
          { model: "Widget", association: "tags" }
        ],
        accessed: []
      )
      results = described_class.detect_unused_eager_loads(data)
      expect(results.length).to eq(1)
    end

    it "handles missing keys gracefully" do
      expect(described_class.detect_unused_eager_loads({})).to be_empty
    end
  end

  describe ".normalize" do
    it "replaces numeric literals with ?" do
      expect(described_class.normalize("SELECT * FROM users WHERE id = 42"))
        .to eq("SELECT * FROM users WHERE id = ?")
    end

    it "replaces string literals with ?" do
      expect(described_class.normalize("SELECT * FROM users WHERE name = 'Alice'"))
        .to eq("SELECT * FROM users WHERE name = ?")
    end

    it "collapses whitespace" do
      expect(described_class.normalize("SELECT  *   FROM   users"))
        .to eq("SELECT * FROM users")
    end

    it "normalizes equivalent queries to the same string" do
      a = described_class.normalize("SELECT * FROM posts WHERE user_id = 1")
      b = described_class.normalize("SELECT * FROM posts WHERE user_id = 99")
      expect(a).to eq(b)
    end
  end
end