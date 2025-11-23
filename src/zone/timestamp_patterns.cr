require "log"

module Zone
  module TimestampPatterns
    P01_ISO8601_WITH_TZ           = /\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?[+-]\d{2}:\d{2}\b/
    P02_ISO8601_ZULU              = /\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\b/
    P03_ISO8601_SPACE_WITH_OFFSET = /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)? [+-]\d{4}\b/
    P04_ISO8601_SPACE             = /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?(?! [+-]\d| [AP]M)/
    P04A_12HR_WITH_TZ             = /\b\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2} [AP]M [A-Z]{3,4}\b/
    P05_PRETTY1_12HR              = /\b[A-Z][a-z]{2} \d{2}, \d{4} - \s?\d{1,2}:\d{2} [AP]M [A-Z]{3,4}\b/
    P06_PRETTY2_24HR              = /\b[A-Z][a-z]{2} \d{2}, \d{4} - \d{2}:\d{2} [A-Z]{3,4}\b/
    P07_PRETTY3_ISO               = /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2} [A-Z]{3,4}\b/
    P08_UNIX_TIMESTAMP            = /(?<![0-9a-fA-F])(?:1\d{9}|2[0-1]\d{8})(?![0-9a-fA-F])/
    P09_RELATIVE_TIME             = /\b\d+\s+(?:second|minute|hour|day|week|month|year)s?\s+(?:ago|from now)\b/i
    P10_GIT_LOG                   = /\b[A-Z][a-z]{2} [A-Z][a-z]{2} \d{1,2} \d{2}:\d{2}:\d{2} \d{4} [+-]\d{4}\b/
    P11_DATE_COMMAND              = /\b[A-Z][a-z]{2} [A-Z][a-z]{2} \d{1,2} \d{2}:\d{2}:\d{2} [A-Z]{3,4} \d{4}\b/
    P12_COMPACT_DATE              = /\b(?:19[7-9]\d|20\d{2})(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\b/

    def self.patterns : Array(Regex)
      [
        P01_ISO8601_WITH_TZ,
        P02_ISO8601_ZULU,
        P03_ISO8601_SPACE_WITH_OFFSET,
        P04A_12HR_WITH_TZ,
        P04_ISO8601_SPACE,
        P05_PRETTY1_12HR,
        P06_PRETTY2_24HR,
        P07_PRETTY3_ISO,
        P08_UNIX_TIMESTAMP,
        P09_RELATIVE_TIME,
        P10_GIT_LOG,
        P11_DATE_COMMAND,
        P12_COMPACT_DATE,
      ]
    end

    def self.match?(text : String) : Bool
      patterns.any? { |pattern| pattern.matches?(text) }
    end

    def self.replace_all(text : String, logger : Log? = nil, &block : String, Regex -> String) : String
      result = text.dup
      matches = 0
      pattern_matches = Hash(String, Int32).new(0)

      patterns.each do |pattern|
        pattern_name = pattern_name_from_constant(pattern)
        result = result.gsub(pattern) do |match|
          next match unless valid_timestamp?(match, pattern)

          matches += 1
          pattern_matches[pattern_name] += 1

          begin
            yield(match, pattern)
          rescue ex
            logger.try &.debug { "Failed to transform '#{match}': #{ex.message}" }
            match # Keep original if transformation fails
          end
        end
      end

      if logger && matches > 0
        logger.debug { "Matched #{matches} timestamp(s)" }
        pattern_matches.each do |name, count|
          plural = count == 1 ? "" : "es"
          logger.debug { "  #{name}: #{count} match#{plural}" }
        end
      end

      result
    end

    private def self.pattern_name_from_constant(pattern : Regex) : String
      case pattern
      when P01_ISO8601_WITH_TZ then "ISO8601_WITH_TZ"
      when P02_ISO8601_ZULU then "ISO8601_ZULU"
      when P03_ISO8601_SPACE_WITH_OFFSET then "ISO8601_SPACE_WITH_OFFSET"
      when P04A_12HR_WITH_TZ then "12HR_WITH_TZ"
      when P04_ISO8601_SPACE then "ISO8601_SPACE"
      when P05_PRETTY1_12HR then "PRETTY1_12HR"
      when P06_PRETTY2_24HR then "PRETTY2_24HR"
      when P07_PRETTY3_ISO then "PRETTY3_ISO"
      when P08_UNIX_TIMESTAMP then "UNIX_TIMESTAMP"
      when P09_RELATIVE_TIME then "RELATIVE_TIME"
      when P10_GIT_LOG then "GIT_LOG"
      when P11_DATE_COMMAND then "DATE_COMMAND"
      when P12_COMPACT_DATE then "COMPACT_DATE"
      else "UNKNOWN"
      end
    end

    private def self.valid_timestamp?(str : String, pattern : Regex) : Bool
      return valid_unix?(str) if pattern == P08_UNIX_TIMESTAMP
      true
    end

    private def self.valid_unix?(str : String) : Bool
      int = str.to_i64
      int >= 1_000_000_000 && int <= 2_100_000_000
    end
  end
end
