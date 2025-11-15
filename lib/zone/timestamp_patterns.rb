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

    # ISO 8601 with space separator and offset (e.g., 2025-01-15 10:30:00 -0500) - Ruby Time.now.to_s format
    P03_ISO8601_SPACE_WITH_OFFSET = /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)? [+-]\d{4}\b/

    # ISO 8601 with space separator, no timezone (e.g., 2025-01-15 10:30:00) - common SQL/database format
    # Use negative lookahead to ensure not followed by timezone offset
    P04_ISO8601_SPACE = /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?(?! [+-]\d)/

    # Zone pretty1 format: 12hr with AM/PM (e.g., "Jan 15, 2025 - 10:30 AM UTC" or "Jan 15, 2025 -  1:30 AM UTC")
    P05_PRETTY1_12HR = /\b[A-Z][a-z]{2} \d{2}, \d{4} - \s?\d{1,2}:\d{2} [AP]M [A-Z]{3,4}\b/

    # Zone pretty2 format: 24hr without AM/PM (e.g., "Jan 15, 2025 - 10:30 UTC")
    P06_PRETTY2_24HR = /\b[A-Z][a-z]{2} \d{2}, \d{4} - \d{2}:\d{2} [A-Z]{3,4}\b/

    # Zone pretty3 format: ISO-style compact (e.g., "2025-01-15 10:30 UTC")
    P07_PRETTY3_ISO = /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2} [A-Z]{3,4}\b/

    # Unix timestamp (10 digits, 2001-2036, e.g., 1736937000)
    # Matches timestamps starting with 1 (2001-2033) or 20-21 (2033-2039)
    # Avoids false positives from phone numbers, order IDs, etc.
    P08_UNIX_TIMESTAMP = /(?<!\d)(?:1\d{9}|2[0-1]\d{8})(?!\d)/

    # Relative time expressions (e.g., "5 hours ago", "3 days from now")
    P09_RELATIVE_TIME = /\b\d+\s+(?:second|minute|hour|day|week|month|year)s?\s+(?:ago|from now)\b/i

    # Git log format (e.g., "Fri Nov 14 23:48:24 2025 +0000", "Wed Nov 5 11:24:19 2025 -0500")
    P10_GIT_LOG = /\b[A-Z][a-z]{2} [A-Z][a-z]{2} \d{1,2} \d{2}:\d{2}:\d{2} \d{4} [+-]\d{4}\b/

    # Date command output format (e.g., "Wed Nov 12 19:13:17 UTC 2025")
    P11_DATE_COMMAND = /\b[A-Z][a-z]{2} [A-Z][a-z]{2} \d{1,2} \d{2}:\d{2}:\d{2} [A-Z]{3,4} \d{4}\b/

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
    # Check if text contains any timestamp patterns.
    #
    # @param [String] text
    #   The text to check
    #
    # @return [Boolean]
    #   true if text matches any timestamp pattern
    #
    def match?(text)
      patterns.any? { |pattern| pattern.match?(text) }
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
      return valid_unix?(str) if pattern == P08_UNIX_TIMESTAMP
      true
    end

    #
    # Validate unix timestamp is in reasonable range.
    #
    # @param [String] str
    #   The matched string
    #
    # @return [Boolean]
    #   true if valid unix timestamp (2001-2036)
    #
    def valid_unix?(str)
      int = str.to_i
      # Range: 2001-09-09 (first 10-digit) to 2036-07-11 (11 years ahead)
      # This avoids false positives from phone numbers, order IDs, etc.
      int >= 1_000_000_000 && int <= 2_100_000_000
    end
  end
end
