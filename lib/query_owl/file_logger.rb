require "json"
require "fileutils"

module QueryOwl
  class FileLogger
    class << self
      def append(events)
        return if events.empty?

        path = QueryOwl.config.log_file
        return unless path

        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "a") do |f|
          events.each { |e| f.puts(JSON.generate(serializable(e))) }
        end
      rescue => e
        Rails.logger.error "[QueryOwl] FileLogger failed: #{e.message}"
      end

      private

        def serializable(event)
          event.transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
        end
    end
  end
end
