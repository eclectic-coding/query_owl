module QueryOwl
  class Configuration
    VALID_LOG_LEVELS = %i[debug info warn].freeze

    attr_reader :log_level
    attr_accessor :enabled, :slow_query_threshold_ms, :n_plus_one_threshold

    def initialize
      @enabled                = Rails.env.development?
      @slow_query_threshold_ms = 100
      @n_plus_one_threshold   = 2
      @log_level              = :warn
    end

    def log_level=(level)
      unless VALID_LOG_LEVELS.include?(level)
        raise ArgumentError, "log_level must be one of #{VALID_LOG_LEVELS.inspect}"
      end

      @log_level = level
    end
  end
end