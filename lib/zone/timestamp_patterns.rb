# frozen_string_literal: true

module Zone
  #
  # Pattern matching for timestamps in arbitrary text.
  #
  # Provides regex patterns and utilities for finding and replacing
  # timestamps embedded in unstructured text.
  #
  module TimestampPatterns
    # Patterns are prefixed with P## to define priority order (most specific first).
    # To add a new pattern, simply define a new Regexp constant with appropriate priority number.
    # It will be automatically included in pattern matching.

    # ISO 8601 with timezone offset (e.g., 2025-01-15T10:30:00+09:00)
    P01_ISO8601_WITH_TZ = /\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?[+-]\d{2}:\d{2}\b/

    # ISO 8601 with Zulu (UTC) timezone (e.g., 2025-01-15T10:30:00Z)
    P02_ISO8601_ZULU = /\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\b/

    # Zone pretty format with year (e.g., "Jan 15, 2025 - 10:30 AM UTC")
    P03_PRETTY_WITH_YEAR = /\b[A-Z][a-z]{2} \d{2}, \d{4} - \d{1,2}:\d{2} [AP]M [A-Z]{3,4}\b/

    # Zone pretty format without year (e.g., "Nov 04 - 06:40 PM PST")
    P04_PRETTY_WITHOUT_YEAR = /\b[A-Z][a-z]{2} \d{2} - \d{1,2}:\d{2} [AP]M [A-Z]{3,4}\b/

    # Unix timestamp (10 digits, e.g., 1736937000)
    P05_UNIX_TIMESTAMP = /\b\d{10}\b/

    # Relative time expressions (e.g., "5 hours ago", "3 days from now")
    P06_RELATIVE_TIME = /\b\d+\s+(?:second|minute|hour|day|week|month|year)s?\s+(?:ago|from now)\b/i

    module_function

    #
    # Returns all timestamp patterns in priority order.
    #
    # @return [Array<Regexp>]
    #   All Regexp constants defined in this module, sorted by P## prefix
    #
    def patterns
      constants
        .select { |c| c.to_s.match?(/^P\d+_/) }
        .sort_by { |c| c.to_s[/^P(\d+)_/, 1].to_i }
        .map { |c| const_get(c) }
    end

    #
    # Replace all timestamp patterns in text.
    #
    # @param [String] text
    #   The text to search for timestamps
    #
    # @param [Logger, nil] logger
    #   Optional logger for debug output
    #
    # @yield [match, pattern]
    #   Block receives each matched timestamp string and its pattern
    #
    # @yieldparam [String] match
    #   The matched timestamp string
    #
    # @yieldparam [Regexp] pattern
    #   The pattern that matched
    #
    # @yieldreturn [String]
    #   The replacement string
    #
    # @return [String]
    #   Text with all timestamps replaced
    #
    # @example
    #   text = "Logged in at 2025-01-15T10:30:00Z"
    #   result = replace_all(text) do |match, pattern|
    #     timestamp = Timestamp.parse(match)
    #     timestamp.to_pretty
    #   end
    #   # => "Logged in at Jan 15, 2025 - 10:30 AM UTC"
    #
    def replace_all(text, logger: nil)
      result = text.dup
      matches = 0

      patterns.each do |pattern|
        result.gsub!(pattern) do |match|
          next match unless valid_timestamp?(match, pattern)

          matches += 1

          begin
            yield(match, pattern)
          rescue StandardError => e
            logger&.debug("Failed to transform '#{match}': #{e.message}")
            match # Keep original if transformation fails
          end
        end
      end

      logger&.debug("Matched #{matches} timestamp(s)") if logger && matches > 0

      result
    end

    #
    # Validate that a matched string is actually a timestamp.
    #
    # @param [String] str
    #   The matched string
    #
    # @param [Regexp] pattern
    #   The pattern that matched
    #
    # @return [Boolean]
    #   true if valid timestamp
    #
    def valid_timestamp?(str, pattern)
      return valid_unix?(str) if pattern == P05_UNIX_TIMESTAMP
      true
    end

    #
    # Validate unix timestamp is in reasonable range.
    #
    # @param [String] str
    #   The matched string
    #
    # @return [Boolean]
    #   true if valid unix timestamp (1970-2100)
    #
    def valid_unix?(str)
      int = str.to_i
      # Range: 1970-01-01 00:00:00 to 2100-01-01 00:00:00
      int >= 0 && int <= 4102444800
    end
  end
end
