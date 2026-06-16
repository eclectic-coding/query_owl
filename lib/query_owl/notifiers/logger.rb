module QueryOwl
  module Notifiers
    # Writes events to the Rails logger at the configured log level.
    # This is the default notifier.
    #
    # @example
    #   config.notifiers = [QueryOwl::Notifiers::Logger.new]
    class Logger
      # @param event [Hash] detected event (must include +:type+ and relevant fields)
      # @return [void]
      def call(event)
        ::Rails.logger.public_send(QueryOwl.config.log_level, "#{QueryOwl::Logger::PREFIX} #{event.to_json}")
      end
    end
  end
end
