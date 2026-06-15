module QueryOwl
  class SlowQueriesController < ApplicationController
    def index
      filters = request.query_parameters
      events  = EventStore.all
      events  = events.select { |e| e[:type].to_s == filters["type"] }       if filters["type"].present?
      events  = events.select { |e| e[:controller] == filters["controller"] } if filters["controller"].present?
      events  = events.select { |e| e[:action] == filters["action"] }         if filters["action"].present?
      render json: events
    end
  end
end
