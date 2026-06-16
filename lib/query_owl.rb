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

module QueryOwl
  class NPlusOneError < StandardError; end

  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def reset_config!
      @config = Configuration.new
    end

    def deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("1.0", "QueryOwl")
    end
  end
end
