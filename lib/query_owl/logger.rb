require "json"

module QueryOwl
  module Logger
    PREFIX = "[QueryOwl]"

    class << self
      def log_events(events)
        return if events.empty?

        events.each { |event| write(event) }
      end

      def log_summary(events)
        return if events.empty?

        counts = events.group_by { |e| e[:type] }.transform_values(&:count)
        parts  = []
        parts << "#{counts[:n_plus_one]} N+1#{"s" if counts[:n_plus_one] != 1}" if counts[:n_plus_one]
        parts << "#{counts[:slow_query]} slow #{counts[:slow_query] == 1 ? "query" : "queries"}" if counts[:slow_query]
        parts << "#{counts[:unused_eager_load]} unused eager load#{"s" if counts[:unused_eager_load] != 1}" if counts[:unused_eager_load]

        Rails.logger.public_send(QueryOwl.config.log_level, "#{PREFIX} Request complete — #{parts.join(", ")}")
      end

      private

      def write(event)
        Rails.logger.public_send(QueryOwl.config.log_level, "#{PREFIX} #{event.to_json}")
      end
    end
  end
end
