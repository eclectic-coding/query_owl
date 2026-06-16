module QueryOwl
  module RequestContext
    class << self
      def set(controller:, action:, path:)
        Thread.current[:query_owl_request_context] = { controller: controller, action: action, path: path }
      end

      def current
        Thread.current[:query_owl_request_context] || {}
      end

      def clear
        Thread.current[:query_owl_request_context] = nil
      end
    end
  end
end
