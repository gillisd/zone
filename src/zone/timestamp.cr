module Zone
  class Timestamp
    property time : Time
    property zone : String?

    def self.parse(input : String | Time) : Timestamp
      time = if input.is_a?(Time)
        input
      elsif input.is_a?(String)
        TimestampParser.parse(input)
      else
        raise ArgumentError.new("Could not parse time '#{input}'")
      end

      new(time)
    rescue ex
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

    def strftime(format : String) : String
      @time.to_s(format)
    end
  end
end
