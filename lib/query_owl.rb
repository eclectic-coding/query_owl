require "query_owl/version"
require "query_owl/configuration"
require "query_owl/query_tracker"
require "query_owl/eager_load_tracker"
require "query_owl/event_store"
require "query_owl/detector"
require "query_owl/logger"
require "query_owl/file_logger"
require "query_owl/notifiers/logger"
require "query_owl/notifiers/stdout"
require "query_owl/notifiers/console"
require "query_owl/request_context"
require "query_owl/middleware"
require "query_owl/engine"

# QueryOwl is a lightweight Rails engine that detects N+1 queries, slow queries,
# and unused eager loads in development, logging structured warnings to your Rails logger.
#
# @example Basic setup in +config/initializers/query_owl.rb+
#   QueryOwl.configure do |config|
#     config.slow_query_threshold_ms = 200
#     config.notifiers               = [QueryOwl::Notifiers::Console.new]
#   end
module QueryOwl
  # Raised instead of notifying when {Configuration#raise_on_n_plus_one} is +true+.
  class NPlusOneError < StandardError; end

  class << self
    # Yields the global {Configuration} object for mutation.
    #
    # @yield [config] the current configuration
    # @yieldparam config [Configuration]
    # @return [void]
    def configure
      yield config
    end

    # @return [Configuration] the global configuration instance
    def config
      @config ||= Configuration.new
    end

    # Resets configuration to defaults. Primarily used in tests.
    #
    # @return [Configuration]
    def reset_config!
      @config = Configuration.new
    end

    # @return [ActiveSupport::Deprecation] the gem's deprecation handler
    def deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("1.0", "QueryOwl")
    end
  end
end
