module Zone
  class Timestamp
    getter time : Time
    getter zone : String?

    def self.parse(input : Time | String) : Timestamp
      time = case input
      when Time
        input
      when String
        if input.matches?(/^[0-9\.]+$/)
          parse_unix(input)
        elsif match = input.match(/^(?<amount>[0-9\.]+) (?<unit>second|minute|hour|day|week|month|year|decade)s? (?<direction>ago|from now)$/)
          parse_relative(match)
        elsif match = input.match(/^(?<dow>[A-Z][a-z]{2}) (?<mon>[A-Z][a-z]{2}) (?<day>\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<year>\d{4}) (?<offset>[+-]\d{4})$/)
          # Git log format: "Fri Nov 14 14:54:35 2025 -0500"
          parse_git_log(match)
        else
          begin
            Time.parse_rfc3339(input)
          rescue
            begin
              Time.parse(input, "%Y-%m-%dT%H:%M:%S%z", Time::Location::UTC)
            rescue
              begin
                Time.parse(input, "%Y-%m-%d+%H:%MZ", Time::Location::UTC)
              rescue
                begin
                  Time.parse(input, "%Y-%m-%d+%H:%M%z", Time::Location::UTC)
                rescue
                  Time.parse(input, "%Y-%m-%d %H:%M:%S", Time::Location.load("Local"))
                end
              end
            end
          end
        end
      else
        raise ArgumentError.new("Unsupported input type")
      end

      new(time)
    rescue ex
      raise ArgumentError.new("Could not parse time '#{input}': #{ex.message}")
    end

    def initialize(@time : Time, @zone : String? = nil)
    end

    def in_zone(zone_name : String) : Timestamp
      location = Zone.find(zone_name)

      raise ArgumentError.new("Could not find timezone '#{zone_name}'") if location.nil?

      converted = @time.in(location)

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
      # Use Z for UTC, otherwise use offset with colon
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
      # %Z gives timezone abbreviation (JST, EST, etc.), but fallback to name if not available
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
      amount = match_data["amount"].to_i
      unit = match_data["unit"]
      direction = match_data["direction"]

      seconds = case unit
      when "second"
        amount
      when "minute"
        amount * 60
      when "hour"
        amount * 3600
      when "day"
        amount * 86400
      when "week"
        amount * 604800
      when "month"
        amount * 2592000
      when "year"
        amount * 31536000
      when "decade"
        amount * 315360000
      else
        0
      end

      case direction
      when "ago"
        Time.local - seconds.seconds
      when "from now"
        Time.local + seconds.seconds
      else
        Time.local
      end
    end

    private def self.parse_git_log(match_data : Regex::MatchData) : Time
      # Git log format: "Fri Nov 14 14:54:35 2025 -0500"
      # Reorder to parseable format
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
