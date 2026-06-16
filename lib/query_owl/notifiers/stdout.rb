module QueryOwl
  module Notifiers
    class Stdout
      def call(event)
        $stdout.puts "#{QueryOwl::Logger::PREFIX} #{event.to_json}"
      end
    end
  end
end