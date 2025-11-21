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
      # Try unix timestamp
      if input.matches?(/^[0-9\.]+$/)
        return parse_unix(input)
      end

      # Try relative time
      if match = input.match(/^(?<amount>[0-9\.]+) (?<unit>second|minute|hour|day|week|month|year|decade)s? (?<direction>ago|from now)$/)
        return parse_relative(match)
      end

      # Try git log format
      if match = input.match(/^(?<dow>[A-Z][a-z]{2}) (?<mon>[A-Z][a-z]{2}) (?<day>\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<year>\d{4}) (?<offset>[+-]\d{4})$/)
        return parse_git_log(match)
      end

      # Try standard parsing methods
      begin
        return Time.parse_rfc3339(input)
      rescue
      end

      begin
        return Time.parse_iso8601(input)
      rescue
      end

      begin
        return Time.parse(input, "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC)
      rescue
      end

      begin
        return Time.parse(input, "%Y-%m-%d %H:%M:%S", Time::Location.local)
      rescue
      end

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
      case style
      when 1
        @time.to_s("%b %d, %Y - %l:%M %P %Z")
      when 2
        @time.to_s("%b %d, %Y - %H:%M %Z")
      when 3
        @time.to_s("%Y-%m-%d %H:%M %Z")
      else
        raise ArgumentError.new("Invalid pretty style '#{style}' (must be 1, 2, or 3)")
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
      # Git log format: "Fri Nov 14 14:54:35 2025 -0500"
      # Reorder to parseable format: "Fri Nov 14 14:54:35 -0500 2025"
      dow = match_data["dow"]
      mon = match_data["mon"]
      day = match_data["day"]
      time = match_data["time"]
      year = match_data["year"]
      offset = match_data["offset"]

      reordered = "#{dow} #{mon} #{day} #{time} #{offset} #{year}"
      Time.parse(reordered, "%a %b %d %H:%M:%S %z %Y", Time::Location::UTC)
    end
  end
end
