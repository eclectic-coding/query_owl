module QueryOwl
  module Notifiers
    # Writes raw JSON events to +$stdout+. Useful when Rails logger is unavailable
    # (e.g. background scripts, non-Rails environments).
    #
    # @example
    #   config.notifiers = [QueryOwl::Notifiers::Stdout.new]
    class Stdout
      # @param event [Hash] detected event (must include +:type+ and relevant fields)
      # @return [void]
      def call(event)
        $stdout.puts "#{QueryOwl::Logger::PREFIX} #{event.to_json}"
      end
    end
  end
end
