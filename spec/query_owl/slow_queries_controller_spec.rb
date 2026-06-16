require "rails_helper"

RSpec.describe QueryOwl::SlowQueriesController, type: :request do
  let(:slow_event)   { { type: :slow_query,        sql: "SELECT 1", duration_ms: 200, controller: "widgets", action: "index", path: "/widgets", backtrace: [], recorded_at: Time.current } }
  let(:n_plus_event) { { type: :n_plus_one,         sql: "SELECT * FROM tags", count: 3, controller: "posts", action: "show", path: "/posts/1", backtrace: [], recorded_at: Time.current } }
  let(:eager_event)  { { type: :unused_eager_load,  model: "Widget", association: :tags, controller: "widgets", action: "index", path: "/widgets", backtrace: [], recorded_at: Time.current } }

  before do
    QueryOwl.config.dashboard_enabled = true
    QueryOwl::EventStore.clear
    [slow_event, n_plus_event, eager_event].each { |e| QueryOwl::EventStore.push(e) }
  end

  after do
    QueryOwl::EventStore.clear
    QueryOwl.reset_config!
  end

  describe "GET /slow_queries (HTML)" do
    it "returns 200" do
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:ok)
    end

    it "renders all events when no filters are applied" do
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response.body).to include("slow query")
      expect(response.body).to include("n plus one")
      expect(response.body).to include("unused eager load")
    end

    it "renders the turbo-frame wrapper" do
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response.body).to include('<turbo-frame id="qo-events">')
    end

    it "renders the filter form" do
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response.body).to include('data-controller="table-filter"')
      expect(response.body).to include('name="type"')
      expect(response.body).to include('name="controller"')
    end

    context "with type filter" do
      it "shows only events matching the type" do
        get "/query_owl/slow_queries", params: { type: "slow_query" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include("slow query")
        expect(response.body).not_to include("n plus one")
        expect(response.body).not_to include("unused eager load")
      end

      it "marks the selected option" do
        get "/query_owl/slow_queries", params: { type: "n_plus_one" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include('value="n_plus_one"')
        expect(response.body).to match(/value="n_plus_one"\s+selected/)
      end

      it "shows a clear link when a filter is active" do
        get "/query_owl/slow_queries", params: { type: "slow_query" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include("Clear")
      end
    end

    context "with controller filter" do
      it "shows only events from the matching controller" do
        get "/query_owl/slow_queries", params: { controller: "widgets" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include("widgets")
        expect(response.body).not_to include("posts")
      end

      it "populates the controller input with the current filter value" do
        get "/query_owl/slow_queries", params: { controller: "widgets" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include('value="widgets"')
      end

      it "matches on a partial controller name (substring)" do
        get "/query_owl/slow_queries", params: { controller: "widg" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include("widgets")
        expect(response.body).not_to include("posts")
      end

      it "renders the clear X button without hidden when a controller filter is set" do
        get "/query_owl/slow_queries", params: { controller: "widgets" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include("qo-input-clear")
        expect(response.body).not_to match(/clearController"[\s\S]*?hidden>/)
      end

      it "renders the clear X button as hidden when no controller filter is set" do
        get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
        expect(response.body).to match(/clearController"[\s\S]*?hidden>/)
      end
    end

    context "with no matching events" do
      it "shows the empty state inside the turbo-frame" do
        get "/query_owl/slow_queries", params: { type: "slow_query", controller: "posts" }, headers: { "Accept" => "text/html" }
        expect(response.body).to include("No events detected yet")
      end
    end

    it "returns 403 when dashboard is disabled" do
      QueryOwl.config.dashboard_enabled = false
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /slow_queries sorting (HTML)" do
    let(:older_event) do
      { type: :slow_query, sql: "SELECT 1", duration_ms: 50, controller: "alpha", action: "index",
        path: "/alpha", backtrace: [], recorded_at: 1.hour.ago }
    end
    let(:newer_event) do
      { type: :n_plus_one, sql: "SELECT * FROM tags", count: 5, controller: "beta", action: "show",
        path: "/beta", backtrace: [], recorded_at: Time.current }
    end

    before do
      QueryOwl::EventStore.clear
      [older_event, newer_event].each { |e| QueryOwl::EventStore.push(e) }
    end

    it "defaults to recorded_at desc (newest first)" do
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      body = response.body
      expect(body.index("beta")).to be < body.index("alpha")
    end

    it "sorts by recorded_at asc (oldest first)" do
      get "/query_owl/slow_queries", params: { sort: "recorded_at", direction: "asc" }, headers: { "Accept" => "text/html" }
      body = response.body
      expect(body.index("alpha")).to be < body.index("beta")
    end

    it "sorts by type asc" do
      get "/query_owl/slow_queries", params: { sort: "type", direction: "asc" }, headers: { "Accept" => "text/html" }
      body = response.body
      expect(body.index("n plus one")).to be < body.index("slow query")
    end

    it "sorts by type desc" do
      get "/query_owl/slow_queries", params: { sort: "type", direction: "desc" }, headers: { "Accept" => "text/html" }
      body = response.body
      expect(body.index("slow query")).to be < body.index("n plus one")
    end

    it "sorts by info (duration_ms/count) asc" do
      # older_event has duration_ms: 50 → numeric 50; newer_event has count: 5 → numeric 5
      # asc: 5 < 50, so newer_event (count: 5) appears first
      get "/query_owl/slow_queries", params: { sort: "info", direction: "asc" }, headers: { "Accept" => "text/html" }
      body = response.body
      expect(body.index("count: 5")).to be < body.index("50ms")
    end

    it "sorts by info desc" do
      get "/query_owl/slow_queries", params: { sort: "info", direction: "desc" }, headers: { "Accept" => "text/html" }
      body = response.body
      expect(body.index("50ms")).to be < body.index("count: 5")
    end

    it "ignores unknown sort column and falls back to recorded_at desc" do
      get "/query_owl/slow_queries", params: { sort: "malicious" }, headers: { "Accept" => "text/html" }
      body = response.body
      expect(body.index("beta")).to be < body.index("alpha")
    end

    it "renders sort links in the table header" do
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response.body).to include("qo-sort-link")
    end

    it "marks the active sort column with qo-sort-active" do
      get "/query_owl/slow_queries", params: { sort: "type", direction: "asc" }, headers: { "Accept" => "text/html" }
      expect(response.body).to include("qo-sort-active")
    end

    it "shows the ▼ indicator for the active desc column" do
      get "/query_owl/slow_queries", params: { sort: "recorded_at", direction: "desc" }, headers: { "Accept" => "text/html" }
      expect(response.body).to include("▼")
    end

    it "shows the ▲ indicator for the active asc column" do
      get "/query_owl/slow_queries", params: { sort: "recorded_at", direction: "asc" }, headers: { "Accept" => "text/html" }
      expect(response.body).to include("▲")
    end
  end

  describe "GET /slow_queries (JSON)" do
    it "still returns JSON when requested" do
      get "/query_owl/slow_queries", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
      expect(JSON.parse(response.body).length).to eq(3)
    end

    it "filters JSON by type param" do
      get "/query_owl/slow_queries", params: { type: "slow_query" }, headers: { "Accept" => "application/json" }
      types = JSON.parse(response.body).map { |e| e["type"] }
      expect(types).to all(eq("slow_query"))
    end
  end
end