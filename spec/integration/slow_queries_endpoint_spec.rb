require "rails_helper"

RSpec.describe "GET /query_owl/slow_queries", type: :request do
  let(:n_plus_one) { { type: :n_plus_one, sql: "SELECT * FROM users WHERE id = ?", count: 3, backtrace: [] } }
  let(:slow_query) { { type: :slow_query, sql: "SELECT * FROM reports", duration_ms: 350, backtrace: [] } }

  before do
    QueryOwl::EventStore.clear
    QueryOwl::EventStore.push(n_plus_one)
    QueryOwl::EventStore.push(slow_query)
  end

  after { QueryOwl::EventStore.clear }

  describe "JSON" do
    it "returns 200" do
      get "/query_owl/slow_queries", as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON content type" do
      get "/query_owl/slow_queries", as: :json
      expect(response.content_type).to include("application/json")
    end

    it "returns all events when no filters are applied" do
      get "/query_owl/slow_queries", as: :json
      body = JSON.parse(response.body)
      expect(body.length).to eq(2)
    end

    it "includes event fields in the response" do
      get "/query_owl/slow_queries", as: :json
      body = JSON.parse(response.body)
      first = body.first
      expect(first["type"]).to eq("n_plus_one")
      expect(first["sql"]).to eq("SELECT * FROM users WHERE id = ?")
      expect(first["recorded_at"]).not_to be_nil
    end

    describe "filtering by type" do
      it "returns only events matching the requested type" do
        get "/query_owl/slow_queries?type=slow_query", as: :json
        body = JSON.parse(response.body)
        expect(body.length).to eq(1)
        expect(body.first["type"]).to eq("slow_query")
      end

      it "returns an empty array when no events match the type" do
        get "/query_owl/slow_queries?type=unused_eager_load", as: :json
        body = JSON.parse(response.body)
        expect(body).to be_empty
      end
    end

    it "returns an empty array when the store is empty" do
      QueryOwl::EventStore.clear
      get "/query_owl/slow_queries", as: :json
      expect(JSON.parse(response.body)).to be_empty
    end
  end

  describe "HTML" do
    it "returns 200 when dashboard_enabled is true" do
      QueryOwl.config.dashboard_enabled = true
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:ok)
    end

    it "returns HTML content type" do
      QueryOwl.config.dashboard_enabled = true
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response.content_type).to include("text/html")
    end

    it "includes event data in the HTML body" do
      QueryOwl.config.dashboard_enabled = true
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response.body).to include("n_plus_one")
      expect(response.body).to include("SELECT * FROM users WHERE id = ?")
    end

    it "returns 403 when dashboard_enabled is false" do
      QueryOwl.config.dashboard_enabled = false
      get "/query_owl/slow_queries", headers: { "Accept" => "text/html" }
      expect(response).to have_http_status(:forbidden)
    end

    it "still returns JSON when dashboard_enabled is false" do
      QueryOwl.config.dashboard_enabled = false
      get "/query_owl/slow_queries", as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end