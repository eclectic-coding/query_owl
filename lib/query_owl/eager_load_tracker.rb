module QueryOwl
  module EagerLoadTracker
    class << self
      def start!
        Thread.current[:query_owl_preloaded] = []
        Thread.current[:query_owl_el_accessed] = Set.new
      end

      def stop!
        result = { preloaded: preloaded.dup, accessed: accessed.dup }
        Thread.current[:query_owl_preloaded] = nil
        Thread.current[:query_owl_el_accessed] = nil
        result
      end

      def tracking?
        !Thread.current[:query_owl_preloaded].nil?
      end

      def record_preload(model_name, association_name)
        return unless tracking?

        preloaded << { model: model_name.to_s, association: association_name.to_s }
      end

      def record_access(model_name, association_name)
        return unless tracking?

        accessed << "#{model_name}##{association_name}"
      end

      private

      def preloaded
        Thread.current[:query_owl_preloaded] ||= []
      end

      def accessed
        Thread.current[:query_owl_el_accessed] ||= Set.new
      end
    end
  end
end
