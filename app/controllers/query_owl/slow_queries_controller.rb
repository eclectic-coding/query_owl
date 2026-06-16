module QueryOwl
  class SlowQueriesController < ActionController::Base
    protect_from_forgery with: :null_session
    layout "query_owl/application"
    helper QueryOwl::ApplicationHelper

    before_action :check_dashboard_enabled, if: -> { request.format.html? }

    def index
      filters = request.query_parameters
      events  = EventStore.all
      events  = events.select { |e| e[:type].to_s == filters["type"] }       if filters["type"].present?
      events  = events.select { |e| e[:controller].to_s.include?(filters["controller"]) } if filters["controller"].present?
      events  = events.select { |e| e[:action] == filters["action"] }         if filters["action"].present?

      respond_to do |format|
        format.json { render json: events }
        format.html do
          @type_filter       = filters["type"].presence
          @controller_filter = filters["controller"].presence
          @events = events.reverse
        end
      end
    end

    private

    def check_dashboard_enabled
      head :forbidden unless QueryOwl.config.dashboard_enabled
    end
  end
end
