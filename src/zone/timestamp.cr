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
        elsif match = input.match(/^(?<dow>[A-Z][a-z]{2}) (?<mon>[A-Z][a-z]{2}) (?<day>\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<tz>[A-Z]{3,4}) (?<year>\d{4})$/)
          # Date command format: "Wed Nov 12 19:13:17 UTC 2025"
          parse_date_command(match)
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
        # Normalize historical timezone offsets to modern standard offsets
        normalized_str = format_with_normalized_offset(@time)
        normalized_str || @time.to_s("%Y-%m-%dT%H:%M:%S%:z")
      end
    end

    def to_unix : Int64
      @time.to_unix
    end

    def to_pretty(style : Int32 = 1) : String
      # Get timezone abbreviation instead of full name
      tz_abbr = TimezoneAbbreviations.get_for_time(@time)

      case style
      when 1
        @time.to_s("%b %d, %Y - %l:%M %P ") + tz_abbr
      when 2
        @time.to_s("%b %d, %Y - %H:%M ") + tz_abbr
      when 3
        @time.to_s("%Y-%m-%d %H:%M ") + tz_abbr
      else
        raise ArgumentError.new("Invalid pretty style '#{style}' (must be 1, 2, or 3)")
      end
    end

    def strftime(format : String) : String
      @time.to_s(format)
    end

    # Format time with normalized offset, handling dates before Unix epoch
    # Returns nil if offset doesn't need normalization
    private def format_with_normalized_offset(time : Time) : String?
      offset_seconds = time.offset

      # Extract hours and minutes from offset
      offset_hours = offset_seconds // 3600
      offset_remainder = offset_seconds % 3600
      offset_minutes = offset_remainder // 60

      # Standard timezone offsets use 0, 15, 30, or 45 minute intervals
      # If we have an unusual minute value (like 18 from LMT), normalize it to nearest hour
      normalized_minutes = case offset_minutes.abs
      when 0, 15, 30, 45
        return nil  # Already standard, no normalization needed
      else
        # Round to nearest hour (0 minutes)
        # If >= 30 minutes, round up to next hour; otherwise round down to 0
        if offset_minutes.abs >= 30
          offset_hours += offset_minutes > 0 ? 1 : -1
          0
        else
          0  # Round down to 0 minutes
        end
      end

      # Calculate normalized offset in seconds
      normalized_offset_seconds = (offset_hours * 3600) + (normalized_minutes * 60)

      # Calculate what the local time should be with the normalized offset
      # Get UTC time and add the normalized offset to get local time
      utc_time = time.to_utc

      # Add the normalized offset to UTC to get the correct local time
      local_time = utc_time + normalized_offset_seconds.seconds

      # Format the offset string
      offset_hours_abs = (normalized_offset_seconds // 3600).abs
      offset_mins_abs = ((normalized_offset_seconds.abs % 3600) // 60)
      offset_sign = normalized_offset_seconds >= 0 ? "+" : "-"
      offset_str = "#{offset_sign}#{offset_hours_abs.to_s.rjust(2, '0')}:#{offset_mins_abs.to_s.rjust(2, '0')}"

      # Format the full ISO8601 string
      "#{local_time.year.to_s.rjust(4, '0')}-#{local_time.month.to_s.rjust(2, '0')}-#{local_time.day.to_s.rjust(2, '0')}T#{local_time.hour.to_s.rjust(2, '0')}:#{local_time.minute.to_s.rjust(2, '0')}:#{local_time.second.to_s.rjust(2, '0')}#{offset_str}"
    end

    # Normalize historical timezone offsets to modern standard offsets
    # This handles cases like Asia/Tokyo in 1901 which used LMT (+09:18:59)
    # instead of the modern JST (+09:00:00)
    private def normalize_offset(time : Time) : Time
      offset_seconds = time.offset

      # Extract hours and minutes from offset
      offset_hours = offset_seconds // 3600  # Integer division
      offset_remainder = offset_seconds % 3600
      offset_minutes = offset_remainder // 60  # Integer division

      # Standard timezone offsets use 0, 15, 30, or 45 minute intervals
      # If we have an unusual minute value (like 18 from LMT), normalize it to nearest hour
      normalized_minutes = case offset_minutes.abs
      when 0, 15, 30, 45
        offset_minutes  # Already standard
      else
        # Round to nearest hour (0 minutes)
        # If >= 30 minutes, round up to next hour; otherwise round down to 0
        if offset_minutes.abs >= 30
          offset_hours += offset_minutes > 0 ? 1 : -1
          0
        else
          0  # Round down to 0 minutes
        end
      end

      # Calculate normalized offset in seconds
      normalized_offset = (offset_hours * 3600) + (normalized_minutes * 60)

      # If offset hasn't changed, return original time
      return time if normalized_offset == offset_seconds

      # Create a new Time with the normalized offset
      # We need to maintain the same UTC moment, just change the offset
      # Convert to UTC unix timestamp, then back with new location
      utc_seconds = time.to_utc.to_unix
      utc_nanos = time.to_utc.nanosecond

      normalized_location = Time::Location.fixed(normalized_offset.to_i32)
      Time.new(seconds: utc_seconds, nanoseconds: utc_nanos, location: normalized_location)
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

    private def self.parse_date_command(match_data : Regex::MatchData) : Time
      # Date command format: "Wed Nov 12 19:13:17 UTC 2025"
      dow = match_data["dow"]
      mon = match_data["mon"]
      day = match_data["day"]
      time = match_data["time"]
      tz = match_data["tz"]
      year = match_data["year"]

      # Parse without timezone first
      base_str = "#{dow} #{mon} #{day} #{time} #{year}"
      parsed = Time.parse(base_str, "%a %b %d %H:%M:%S %Y", Time::Location::UTC)

      # If timezone is not UTC, try to find and apply it
      if tz != "UTC"
        if location = Zone.find(tz)
          # The time is in the specified timezone, convert to that location
          parsed.in(location)
        else
          parsed
        end
      else
        parsed
      end
    end
  end
end
