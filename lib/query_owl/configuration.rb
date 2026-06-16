module QueryOwl
  # Holds all configuration for QueryOwl. Use {QueryOwl.configure} to set options.
  #
  # @example
  #   QueryOwl.configure do |config|
  #     config.enabled                 = true
  #     config.slow_query_threshold_ms = 200
  #     config.n_plus_one_threshold    = 3
  #     config.notifiers               = [QueryOwl::Notifiers::Console.new]
  #   end
  class Configuration
    VALID_LOG_LEVELS = %i[debug info warn].freeze
    DEFAULT_BACKTRACE_FILTER = ->(line) { line !~ %r{/gems/|/rubygems/|/ruby/gems/|lib/query_owl/} }

    # @!attribute [rw] enabled
    #   @return [Boolean] whether detection is active (default: +true+ in development)

    # @!attribute [rw] slow_query_threshold_ms
    #   @return [Integer] queries exceeding this duration (ms) are flagged (default: +100+)

    # @!attribute [rw] n_plus_one_threshold
    #   @return [Integer] minimum repeated query count before N+1 is reported (default: +2+)

    # @!attribute [rw] backtrace_lines
    #   @return [Integer] number of backtrace lines included in events (default: +5+)

    # @!attribute [rw] raise_on_n_plus_one
    #   @return [Boolean] raise {QueryOwl::NPlusOneError} instead of notifying (default: +false+)

    # @!attribute [rw] event_store_size
    #   @return [Integer] maximum events retained by the in-memory store (default: +100+)

    # @!attribute [rw] dashboard_enabled
    #   @return [Boolean] mount the QueryOwl dashboard (default: +true+ in development)

    # @!attribute [rw] log_file
    #   @return [String, nil] path for a dedicated log file; +nil+ disables file logging (default: +nil+)

    # @!attribute [rw] ignore_paths
    #   @return [Array<String, Regexp>] request paths excluded from detection

    # @!attribute [rw] ignore_controllers
    #   @return [Array<String>] controller names (e.g. +"ApplicationController"+) excluded from detection

    attr_reader :log_level, :backtrace_filter
    attr_accessor :enabled, :slow_query_threshold_ms, :n_plus_one_threshold, :backtrace_lines,
                  :raise_on_n_plus_one, :event_store_size, :dashboard_enabled, :log_file,
                  :ignore_paths, :ignore_controllers

    # @return [Array<#call>] active notifiers (default: +[Notifiers::Logger.new]+)
    def notifiers
      @notifiers ||= [Notifiers::Logger.new]
    end

    # @param arr [Array<#call>] each element must respond to +#call+
    # @raise [ArgumentError] if any element does not respond to +#call+
    def notifiers=(arr)
      arr.each do |notifier|
        unless notifier.respond_to?(:call)
          raise ArgumentError, "notifiers must respond to #call (#{notifier.class} does not)"
        end
      end
      @notifiers = arr
    end

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
      @ignore_paths            = []
      @ignore_controllers      = []
    end

    # @param level [Symbol] one of +:debug+, +:info+, +:warn+
    # @raise [ArgumentError] if level is not a valid log level
    def log_level=(level)
      unless VALID_LOG_LEVELS.include?(level)
        raise ArgumentError, "log_level must be one of #{VALID_LOG_LEVELS.inspect}"
      end

      @log_level = level
    end

    # @param filter [#call] callable that receives a backtrace line and returns +true+ to keep it
    # @raise [ArgumentError] if filter does not respond to +#call+
    def backtrace_filter=(filter)
      raise ArgumentError, "backtrace_filter must respond to #call" unless filter.respond_to?(:call)

      @backtrace_filter = filter
    end
  end
end
