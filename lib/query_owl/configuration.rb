module QueryOwl
  class Configuration
    VALID_LOG_LEVELS = %i[debug info warn].freeze
    DEFAULT_BACKTRACE_FILTER = ->(line) { line !~ %r{/gems/|/rubygems/|/ruby/gems/|lib/query_owl/} }

    attr_reader :log_level, :backtrace_filter
    attr_accessor :enabled, :slow_query_threshold_ms, :n_plus_one_threshold, :backtrace_lines,
                  :raise_on_n_plus_one, :event_store_size, :dashboard_enabled, :log_file

    def initialize
      @enabled                 = Rails.env.development?
      @slow_query_threshold_ms = 100
      @n_plus_one_threshold    = 2
      @log_level               = :warn
      @backtrace_lines         = 5
      @backtrace_filter        = DEFAULT_BACKTRACE_FILTER
      @raise_on_n_plus_one     = false
      @event_store_size        = 100
      @dashboard_enabled       = Rails.env.development?
      @log_file                = nil
    end

    def log_level=(level)
      unless VALID_LOG_LEVELS.include?(level)
        raise ArgumentError, "log_level must be one of #{VALID_LOG_LEVELS.inspect}"
      end

      @log_level = level
    end

    def backtrace_filter=(filter)
      raise ArgumentError, "backtrace_filter must respond to #call" unless filter.respond_to?(:call)

      @backtrace_filter = filter
    end
  end
end
