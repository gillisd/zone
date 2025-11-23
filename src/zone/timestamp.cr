module Zone
  class Timestamp
    property time : Time
    property zone : String?

    def self.parse(input : String | Time) : Timestamp
      time = if input.is_a?(Time)
        input
      elsif input.is_a?(String)
        parse_string(input)
      else
        raise ArgumentError.new("Could not parse time '#{input}'")
      end

      new(time)
    rescue ex
      raise ArgumentError.new("Could not parse time '#{input}'")
    end

    private def self.parse_string(input : String) : Time
      return parse_unix(input) if input.matches?(/^[0-9]{10,}(?:\.[0-9]+)?$/)

      if match = input.match(/^(?<amount>[0-9\.]+) (?<unit>second|minute|hour|day|week|month|year|decade)s? (?<direction>ago|from now)$/)
        return parse_relative(match)
      end

      if match = input.match(/^(?<dow>[A-Z][a-z]{2}) (?<mon>[A-Z][a-z]{2}) (?<day>\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<year>\d{4}) (?<offset>[+-]\d{4})$/)
        return parse_git_log(match)
      end

      if match = input.match(/^(?<dow>[A-Z][a-z]{2}) (?<mon>[A-Z][a-z]{2}) (?<day>\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<zone>\w+) (?<year>\d{4})$/)
        return parse_date_command(match)
      end

      if match = input.match(/^(?<date>\d{4}-\d{2}-\d{2}) (?<hour>\d{1,2}):(?<min>\d{2}):(?<sec>\d{2}) (?<ampm>[AP]M) (?<zone>\w+)$/)
        return parse_12hour_with_zone(match)
      end

      if match = input.match(/^(?<year>19[7-9]\d|20\d{2})(?<month>0[1-9]|1[0-2])(?<day>0[1-9]|[12]\d|3[01])$/)
        return Time.parse("#{match["year"]}-#{match["month"]}-#{match["day"]}", "%Y-%m-%d", Time::Location.local) rescue nil
      end

      if match = input.match(/^(\d{4}-\d{2}-\d{2})([\+\-]\d{2}:\d{2})Z?$/)
        return Time.parse("#{match[1]}T00:00:00#{match[2]}", "%Y-%m-%dT%H:%M:%S%:z", Time::Location::UTC) rescue nil
      end

      (Time.parse_rfc3339(input) rescue nil) ||
        (Time.parse_iso8601(input) rescue nil) ||
        (Time.parse(input, "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC) rescue nil) ||
        (Time.parse(input, "%Y-%m-%d %H:%M:%S", Time::Location.local) rescue nil) ||
        raise ArgumentError.new("Could not parse time '#{input}'")
    end

    def initialize(@time : Time, @zone : String? = nil)
    end

    def in_zone(zone_name : String) : Timestamp
      tz = Zone.find(zone_name)

      raise ArgumentError.new("Could not find timezone '#{zone_name}'") if tz.nil?

      converted = @time.in(tz)

      self.class.new(
        converted,
        zone: zone_name
      )
    end

    def in_utc : Timestamp
      self.class.new(
        @time.to_utc,
        zone: "UTC"
      )
    end

    def in_local : Timestamp
      self.class.new(
        @time.to_local,
        zone: "local"
      )
    end

    def to_iso8601 : String
      if @time.offset == 0
        @time.to_s("%Y-%m-%dT%H:%M:%SZ")
      else
        @time.to_s("%Y-%m-%dT%H:%M:%S%:z")
      end
    end

    def to_unix : Int64
      @time.to_unix
    end

    def to_pretty(style : Int32 = 1) : String
      zone_abbr = @time.zone.name || @time.location.name

      case style
      when 1
        base = @time.to_s("%b %d, %Y - %l:%M %P")
        "#{base} #{zone_abbr}"
      when 2
        base = @time.to_s("%b %d, %Y - %H:%M")
        "#{base} #{zone_abbr}"
      when 3
        base = @time.to_s("%Y-%m-%d %H:%M")
        "#{base} #{zone_abbr}"
      else
        raise ArgumentError.new("Invalid pretty style '#{style}' (must be 1, 2, or 3)")
      end
    end

    private def self.load_timezone(name : String) : Time::Location
      case name
      when "UTC" then Time::Location::UTC
      when "Local" then Time::Location.local
      else
        Time::Location.load(name) rescue Time::Location::UTC
      end
    end

    private def self.convert_to_24hour(hour : Int32, meridiem : String) : Int32
      case meridiem
      when "PM"
        hour == 12 ? 12 : hour + 12
      when "AM"
        hour == 12 ? 0 : hour
      else
        hour
      end
    end

    def strftime(format : String) : String
      @time.to_s(format)
    end

    private def self.parse_unix(str : String) : Time
      precision = str.size - 10
      time_float = str.to_f / (10 ** precision)
      Time.unix(time_float.to_i64)
    end

    private def self.parse_relative(match_data : Regex::MatchData) : Time
      amount = match_data["amount"]
      unit = match_data["unit"]
      direction = match_data["direction"]

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

    private def self.parse_git_log(match_data : Regex::MatchData) : Time
      reordered = "#{match_data["dow"]} #{match_data["mon"]} #{match_data["day"]} " \
                  "#{match_data["time"]} #{match_data["offset"]} #{match_data["year"]}"
      Time.parse(reordered, "%a %b %d %H:%M:%S %z %Y", Time::Location::UTC)
    end

    private def self.parse_date_command(match_data : Regex::MatchData) : Time
      location = load_timezone(match_data["zone"])
      time_str = "#{match_data["dow"]} #{match_data["mon"]} #{match_data["day"]} " \
                 "#{match_data["time"]} #{match_data["year"]}"
      Time.parse(time_str, "%a %b %d %H:%M:%S %Y", location)
    end

    private def self.parse_12hour_with_zone(match_data : Regex::MatchData) : Time
      hour_24 = convert_to_24hour(match_data["hour"].to_i, match_data["ampm"])
      location = load_timezone(match_data["zone"])
      time_str = "#{match_data["date"]} #{hour_24.to_s.rjust(2, '0')}:#{match_data["min"]}:#{match_data["sec"]}"
      Time.parse(time_str, "%Y-%m-%d %H:%M:%S", location)
    end
  end
end
