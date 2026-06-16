module QueryOwl
  module Notifiers
    class Logger
      def call(event)
        ::Rails.logger.public_send(QueryOwl.config.log_level, "#{QueryOwl::Logger::PREFIX} #{event.to_json}")
      end
    end
  end
end