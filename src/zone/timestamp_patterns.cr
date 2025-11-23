require "log"

module Zone
  module TimestampPatterns
    # Legacy regex constants for backward compatibility
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

    def self.pattern_instances : Array(TimestampPattern)
      @@pattern_instances ||= [
        ISO8601WithTzPattern.new,
        ISO8601ZuluPattern.new,
        ISO8601SpaceWithOffsetPattern.new,
        TwelveHourWithTzPattern.new,
        ISO8601SpacePattern.new,
        Pretty1TwelveHourPattern.new,
        Pretty2TwentyFourHourPattern.new,
        Pretty3IsoPattern.new,
        UnixTimestampPattern.new,
        RelativeTimePattern.new,
        GitLogPattern.new,
        DateCommandPattern.new,
        CompactDatePattern.new,
        DateWithOffsetPattern.new,
      ]
    end

    def self.patterns : Array(Regex)
      pattern_instances.map(&.pattern)
    end

    def self.match?(text : String) : Bool
      patterns.any? { |pattern| pattern.matches?(text) }
    end

    def self.replace_all(text : String, logger : Log? = nil, &block : String, Regex -> String) : String
      result = text.dup
      matches = 0
      pattern_matches = Hash(String, Int32).new(0)

      pattern_instances.each do |pattern_obj|
        result = result.gsub(pattern_obj.pattern) do |match|
          next match unless pattern_obj.valid?(match)

          matches += 1
          pattern_matches[pattern_obj.name] += 1

          begin
            yield(match, pattern_obj.pattern)
          rescue ex
            logger.try &.debug { "Failed to transform '#{match}': #{ex.message}" }
            match
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
  end
end
