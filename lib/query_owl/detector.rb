module QueryOwl
  module Detector
    # Matches numeric literals, single-quoted strings, and IN-list contents.
    NORMALIZE_PATTERNS = [
      [/'[^']*'/, "?"],
      [/\b\d+\b/, "?"],
      [/\s+/, " "]
    ].freeze

    class << self
      def detect_n_plus_one(queries)
        threshold = QueryOwl.config.n_plus_one_threshold

        queries
          .reject { |q| q[:cached] }
          .group_by { |q| normalize(q[:sql]) }
          .filter_map do |normalized_sql, group|
            next if group.length < threshold

            {
              type: :n_plus_one,
              sql: normalized_sql,
              count: group.length,
              backtrace: group.first[:backtrace]
            }
          end
      end

      def detect_slow_queries(queries)
        threshold = QueryOwl.config.slow_query_threshold_ms

        queries.filter_map do |q|
          next if q[:cached]
          next if q[:duration_ms] < threshold

          {
            type: :slow_query,
            sql: normalize(q[:sql]),
            duration_ms: q[:duration_ms],
            backtrace: q[:backtrace]
          }
        end
      end

      def detect_unused_eager_loads(eager_data)
        preloaded = eager_data[:preloaded] || []
        accessed  = eager_data[:accessed]  || Set.new

        preloaded
          .uniq { |e| "#{e[:model]}##{e[:association]}" }
          .reject { |e| accessed.include?("#{e[:model]}##{e[:association]}") }
          .map { |e| { type: :unused_eager_load, model: e[:model], association: e[:association] } }
      end

      def normalize(sql)
        NORMALIZE_PATTERNS
          .reduce(sql.to_s) { |s, (pattern, replacement)| s.gsub(pattern, replacement) }
          .strip
      end
    end
  end
end
