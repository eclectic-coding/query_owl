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

      def normalize(sql)
        NORMALIZE_PATTERNS
          .reduce(sql.to_s) { |s, (pattern, replacement)| s.gsub(pattern, replacement) }
          .strip
      end
    end
  end
end
