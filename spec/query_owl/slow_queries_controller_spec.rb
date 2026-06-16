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