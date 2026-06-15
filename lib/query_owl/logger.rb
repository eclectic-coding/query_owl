require "json"

module QueryOwl
  module Logger
    PREFIX = "[QueryOwl]"

    class << self
      def log_events(events)
        return if events.empty?

        events.each { |event| write(event) }
      end

      private

      def write(event)
        Rails.logger.public_send(QueryOwl.config.log_level, "#{PREFIX} #{event.to_json}")
      end
    end
  end
end
