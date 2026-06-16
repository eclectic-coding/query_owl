module QueryOwl
  module Notifiers
    class Console
      YELLOW = "\e[33m"
      RED    = "\e[31m"
      RESET  = "\e[0m"

      def call(event)
        line = format(event)
        line = apply_color(event[:type], line) if $stdout.tty?
        $stdout.puts line
      end

      private

        def format(event)
          case event[:type]
          when :n_plus_one
            "#{QueryOwl::Logger::PREFIX} n_plus_one  #{event[:sql]}  ×#{event[:count]}"
          when :slow_query
            "#{QueryOwl::Logger::PREFIX} slow_query  #{event[:sql]}  #{event[:duration_ms]}ms"
          when :unused_eager_load
            "#{QueryOwl::Logger::PREFIX} unused_eager_load  #{event[:model]}##{event[:association]}"
          else
            "#{QueryOwl::Logger::PREFIX} #{event[:type]}"
          end
        end

        def apply_color(type, text)
          case type
          when :n_plus_one then "#{YELLOW}#{text}#{RESET}"
          when :slow_query  then "#{RED}#{text}#{RESET}"
          else text
          end
        end
    end
  end
end
