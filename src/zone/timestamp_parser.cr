module Zone
  class TimestampParser
    def self.parse(input : String) : Time
      pattern_instances.each do |pattern|
        next unless pattern.matches?(input)
        next unless pattern.valid?(input)

        if time = pattern.parse(input)
          return time
        end
      end

      fallback_parse(input)
    end

    private def self.pattern_instances : Array(TimestampPattern)
      TimestampPatterns.pattern_instances
    end

    private def self.fallback_parse(input : String) : Time
      (Time.parse_rfc3339(input) rescue nil) ||
        (Time.parse_iso8601(input) rescue nil) ||
        (Time.parse(input, "%Y-%m-%d %H:%M:%S %z", Time::Location::UTC) rescue nil) ||
        (Time.parse(input, "%Y-%m-%d %H:%M:%S", Time::Location.local) rescue nil) ||
        raise ArgumentError.new("Could not parse time '#{input}'")
    end
  end
end
