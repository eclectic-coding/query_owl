module QueryOwl
  class SlowQueriesController < ActionController::Base
    protect_from_forgery with: :null_session
    layout "query_owl/application"
    helper QueryOwl::ApplicationHelper

    before_action :check_dashboard_enabled, if: -> { request.format.html? }

    SORTABLE_COLUMNS = %w[type info recorded_at].freeze

    def index
      filters = request.query_parameters
      events  = EventStore.all
      events  = events.select { |e| e[:type].to_s == filters["type"] }                     if filters["type"].present?
      events  = events.select { |e| e[:controller].to_s.include?(filters["controller"]) }  if filters["controller"].present?
      events  = events.select { |e| e[:action] == filters["action"] }                      if filters["action"].present?

      respond_to do |format|
        format.json { render json: events }
        format.html do
          @type_filter       = filters["type"].presence
          @controller_filter = filters["controller"].presence
          @sort              = SORTABLE_COLUMNS.include?(filters["sort"]) ? filters["sort"] : "recorded_at"
          @direction         = filters["direction"] == "asc" ? "asc" : "desc"
          @events            = sorted_events(events, @sort, @direction)
        end
      end
    end

    private

      def sorted_events(events, sort, direction)
        sorted = case sort
        when "type"
                   events.sort_by { |e| e[:type].to_s }
        when "info"
                   events.sort_by { |e| e[:duration_ms] || e[:count] || 0 }
        else
                   events.sort_by { |e| e[:recorded_at] || Time.at(0) }
        end
        direction == "asc" ? sorted : sorted.reverse
      end

      def check_dashboard_enabled
        head :forbidden unless QueryOwl.config.dashboard_enabled
      end
  end
end
