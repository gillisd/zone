module Zone
  abstract class TimestampPattern
    abstract def pattern : Regex
    abstract def parse(input : String) : Time?
    abstract def name : String

    def matches?(input : String) : Bool
      !pattern.match(input).nil?
    end

    def valid?(input : String) : Bool
      true
    end
  end

  class ISO8601WithTzPattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?[+-]\d{2}:\d{2}\b/
    end

    def parse(input : String) : Time?
      Time.parse_rfc3339(input) rescue nil
    end

    def name : String
      "ISO8601_WITH_TZ"
    end
  end

  class ISO8601ZuluPattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\b/
    end

    def parse(input : String) : Time?
      Time.parse_rfc3339(input) rescue nil
    end

    def name : String
      "ISO8601_ZULU"
    end
  end

  class ISO8601SpaceWithOffsetPattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)? [+-]\d{4}\b/
    end

    def parse(input : String) : Time?
      Time.parse(input, "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC) rescue nil
    end

    def name : String
      "ISO8601_SPACE_WITH_OFFSET"
    end
  end

  class TwelveHourWithTzPattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2} [AP]M [A-Z]{3,4}\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<date>\d{4}-\d{2}-\d{2}) (?<hour>\d{1,2}):(?<min>\d{2}):(?<sec>\d{2}) (?<ampm>[AP]M) (?<zone>\w+)$/)
        hour_24 = convert_to_24hour(match["hour"].to_i, match["ampm"])
        location = load_timezone(match["zone"])
        time_str = "#{match["date"]} #{hour_24.to_s.rjust(2, '0')}:#{match["min"]}:#{match["sec"]}"
        Time.parse(time_str, "%Y-%m-%d %H:%M:%S", location) rescue nil
      end
    end

    def name : String
      "12HR_WITH_TZ"
    end

    private def load_timezone(name : String) : Time::Location
      case name
      when "UTC" then Time::Location::UTC
      when "Local" then Time::Location.local
      else
        Time::Location.load(name) rescue Time::Location::UTC
      end
    end

    private def convert_to_24hour(hour : Int32, meridiem : String) : Int32
      case meridiem
      when "PM"
        hour == 12 ? 12 : hour + 12
      when "AM"
        hour == 12 ? 0 : hour
      else
        hour
      end
    end
  end

  class ISO8601SpacePattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?(?! [+-]\d| [AP]M)/
    end

    def parse(input : String) : Time?
      Time.parse(input, "%Y-%m-%d %H:%M:%S", Time::Location.local) rescue nil
    end

    def name : String
      "ISO8601_SPACE"
    end
  end

  class Pretty1TwelveHourPattern < TimestampPattern
    def pattern : Regex
      /\b[A-Z][a-z]{2} \d{2}, \d{4} - \s?\d{1,2}:\d{2} [AP]M [A-Z]{3,4}\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<mon>[A-Z][a-z]{2}) (?<day>\d{2}), (?<year>\d{4}) - \s?(?<hour>\d{1,2}):(?<min>\d{2}) (?<ampm>[AP]M) (?<zone>[A-Z]{3,4})$/)
        hour_24 = convert_to_24hour(match["hour"].to_i, match["ampm"])
        location = load_timezone(match["zone"])
        time_str = "#{match["mon"]} #{match["day"]} #{match["year"]} #{hour_24.to_s.rjust(2, '0')}:#{match["min"]}:00"
        Time.parse(time_str, "%b %d %Y %H:%M:%S", location) rescue nil
      end
    end

    def name : String
      "PRETTY1_12HR"
    end

    private def load_timezone(name : String) : Time::Location
      case name
      when "UTC" then Time::Location::UTC
      when "Local" then Time::Location.local
      else
        Time::Location.load(name) rescue Time::Location::UTC
      end
    end

    private def convert_to_24hour(hour : Int32, meridiem : String) : Int32
      case meridiem
      when "PM"
        hour == 12 ? 12 : hour + 12
      when "AM"
        hour == 12 ? 0 : hour
      else
        hour
      end
    end
  end

  class Pretty2TwentyFourHourPattern < TimestampPattern
    def pattern : Regex
      /\b[A-Z][a-z]{2} \d{2}, \d{4} - \d{2}:\d{2} [A-Z]{3,4}\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<mon>[A-Z][a-z]{2}) (?<day>\d{2}), (?<year>\d{4}) - (?<hour>\d{2}):(?<min>\d{2}) (?<zone>[A-Z]{3,4})$/)
        location = load_timezone(match["zone"])
        time_str = "#{match["mon"]} #{match["day"]} #{match["year"]} #{match["hour"]}:#{match["min"]}:00"
        Time.parse(time_str, "%b %d %Y %H:%M:%S", location) rescue nil
      end
    end

    def name : String
      "PRETTY2_24HR"
    end

    private def load_timezone(name : String) : Time::Location
      case name
      when "UTC" then Time::Location::UTC
      when "Local" then Time::Location.local
      else
        Time::Location.load(name) rescue Time::Location::UTC
      end
    end
  end

  class Pretty3IsoPattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2} \d{2}:\d{2} [A-Z]{3,4}\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}) (?<zone>[A-Z]{3,4})$/)
        location = load_timezone(match["zone"])
        time_str = "#{match["date"]} #{match["time"]}:00"
        Time.parse(time_str, "%Y-%m-%d %H:%M:%S", location) rescue nil
      end
    end

    def name : String
      "PRETTY3_ISO"
    end

    private def load_timezone(name : String) : Time::Location
      case name
      when "UTC" then Time::Location::UTC
      when "Local" then Time::Location.local
      else
        Time::Location.load(name) rescue Time::Location::UTC
      end
    end
  end

  class UnixTimestampPattern < TimestampPattern
    def pattern : Regex
      # Match 10, 13, or 16 digit unix timestamps
      /(?<![0-9a-fA-F])(?:1\d{9}(?:\d{3}(?:\d{3})?)?|2[0-1]\d{8}(?:\d{3}(?:\d{3})?)?)(?![0-9a-fA-F])/
    end

    def parse(input : String) : Time?
      if input.matches?(/^[0-9]{10,}(?:\.[0-9]+)?$/)
        len = input.size

        if input.includes?('.')
          # Handle decimal unix timestamps (e.g., "1736937000.123")
          time_float = input.to_f
          Time.unix(time_float.to_i64)
        elsif len == 10
          # Standard unix timestamp (seconds)
          Time.unix(input.to_i64)
        elsif len == 13
          # Milliseconds
          Time.unix_ms(input.to_i64)
        elsif len == 16
          # Microseconds
          Time.unix_ms(input.to_i64 // 1000)
        else
          # Unknown precision, treat as seconds
          Time.unix(input.to_i64)
        end
      end
    rescue
      nil
    end

    def name : String
      "UNIX_TIMESTAMP"
    end

    def valid?(input : String) : Bool
      # For pattern matching, check 10-digit range
      if input.size == 10
        int = input.to_i64
        int >= 1_000_000_000 && int <= 2_100_000_000
      else
        # For longer timestamps (ms, us), just check it's numeric
        input.matches?(/^[0-9]{10,}(?:\.[0-9]+)?$/)
      end
    rescue
      false
    end
  end

  class RelativeTimePattern < TimestampPattern
    def pattern : Regex
      /\b\d+\s+(?:second|minute|hour|day|week|month|year)s?\s+(?:ago|from now)\b/i
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<amount>[0-9\.]+) (?<unit>second|minute|hour|day|week|month|year|decade)s? (?<direction>ago|from now)$/)
        amount = match["amount"]
        unit = match["unit"]
        direction = match["direction"]

        seconds = case unit
        when "second"
          amount.to_i
        when "minute"
          amount.to_i * 60
        when "hour"
          amount.to_i * 3600
        when "day"
          amount.to_i * 86400
        when "week"
          amount.to_i * 604800
        when "month"
          amount.to_i * 2592000
        when "year"
          amount.to_i * 31536000
        when "decade"
          amount.to_i * 315360000
        else
          0
        end

        case direction
        when "ago"
          Time.utc - Time::Span.new(seconds: seconds)
        when "from now"
          Time.utc + Time::Span.new(seconds: seconds)
        else
          Time.utc
        end
      end
    rescue
      nil
    end

    def name : String
      "RELATIVE_TIME"
    end
  end

  class GitLogPattern < TimestampPattern
    def pattern : Regex
      /\b[A-Z][a-z]{2} [A-Z][a-z]{2} \d{1,2} \d{2}:\d{2}:\d{2} \d{4} [+-]\d{4}\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<dow>[A-Z][a-z]{2}) (?<mon>[A-Z][a-z]{2}) (?<day>\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<year>\d{4}) (?<offset>[+-]\d{4})$/)
        reordered = "#{match["dow"]} #{match["mon"]} #{match["day"]} " \
                    "#{match["time"]} #{match["offset"]} #{match["year"]}"
        Time.parse(reordered, "%a %b %d %H:%M:%S %z %Y", Time::Location::UTC) rescue nil
      end
    end

    def name : String
      "GIT_LOG"
    end
  end

  class DateCommandPattern < TimestampPattern
    def pattern : Regex
      /\b[A-Z][a-z]{2} [A-Z][a-z]{2} \d{1,2} \d{2}:\d{2}:\d{2} [A-Z]{3,4} \d{4}\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<dow>[A-Z][a-z]{2}) (?<mon>[A-Z][a-z]{2}) (?<day>\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<zone>\w+) (?<year>\d{4})$/)
        location = load_timezone(match["zone"])
        time_str = "#{match["dow"]} #{match["mon"]} #{match["day"]} " \
                   "#{match["time"]} #{match["year"]}"
        Time.parse(time_str, "%a %b %d %H:%M:%S %Y", location) rescue nil
      end
    end

    def name : String
      "DATE_COMMAND"
    end

    private def load_timezone(name : String) : Time::Location
      case name
      when "UTC" then Time::Location::UTC
      when "Local" then Time::Location.local
      else
        Time::Location.load(name) rescue Time::Location::UTC
      end
    end
  end

  class CompactDatePattern < TimestampPattern
    def pattern : Regex
      /\b(?:19[7-9]\d|20\d{2})(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\d|3[01])\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(?<year>19[7-9]\d|20\d{2})(?<month>0[1-9]|1[0-2])(?<day>0[1-9]|[12]\d|3[01])$/)
        Time.parse("#{match["year"]}-#{match["month"]}-#{match["day"]}", "%Y-%m-%d", Time::Location.local) rescue nil
      end
    end

    def name : String
      "COMPACT_DATE"
    end
  end

  class DateWithOffsetPattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2}[+-]\d{2}:\d{2}Z?\b/
    end

    def parse(input : String) : Time?
      if match = input.match(/^(\d{4}-\d{2}-\d{2})([\+\-]\d{2}:\d{2})Z?$/)
        Time.parse("#{match[1]}T00:00:00#{match[2]}", "%Y-%m-%dT%H:%M:%S%:z", Time::Location::UTC) rescue nil
      end
    end

    def name : String
      "DATE_WITH_OFFSET"
    end
  end
end
