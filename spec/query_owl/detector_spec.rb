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