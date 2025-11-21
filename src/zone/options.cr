require "option_parser"

module Zone
  class Options
    property fields : Array(String)
    property delimiter : String
    property zone : String
    property format : Symbol | Hash(Symbol, String | Int32)
    property color : String
    property headers : Bool
    property verbose : Bool
    property silent : Bool

    def initialize
      @fields = [] of String
      @delimiter = ""
      @zone = "local"
      @format = {:pretty => 1} of Symbol => (String | Int32)
      @color = "auto"
      @headers = false
      @verbose = false
      @silent = false
    end

    # Compatibility method - returns first field or nil
    def field : String?
      @fields.first?
    end

    def parse!(argv : Array(String))
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: zone [options] [timestamps...]"
        opts.separator ""
        opts.separator "Examples:"
        opts.separator "  echo 'Event at 2025-01-15T10:30:00Z' | zone           # Convert timestamps in text"
        opts.separator "  zone '2025-01-15T10:30:00Z' --zone tokyo              # Fuzzy timezone matching"
        opts.separator "  cat data.csv | zone --field 2 --delimiter ','         # Convert specific field"

        opts.separator ""
        opts.separator "Timezone Options:"
        opts.on("--zone TZ", "-z", "Convert to time zone (fuzzy matching: 'tokyo' works)") do |tz|
          @zone = tz
        end

        opts.on("--local", "Convert to local time zone") do
          @zone = "local"
        end

        opts.on("--utc", "Convert to UTC") do
          @zone = "utc"
        end

        opts.separator ""
        opts.separator "Output Formats:"
        opts.on("--iso8601", "ISO 8601 format (2025-01-15T10:30:00Z)") do
          @format = :to_iso8601
        end

        opts.on("-p [STYLE]", "--pretty [STYLE]", "Human-readable format (1=12hr, 2=24hr, 3=compact, default: 1)") do |style|
          style_int = (style.nil? || style.empty?) ? 1 : style.to_i
          unless [1, 2, 3].includes?(style_int)
            raise ArgumentError.new("Invalid pretty format -p#{style_int} (must be 1, 2, or 3)")
          end
          @format = {:pretty => style_int} of Symbol => (String | Int32)
        end

        opts.on("--unix", "Unix timestamp (1736937000)") do
          @format = :to_unix
        end

        opts.on("-f FORMAT", "--strftime FORMAT", "Custom format using strftime") do |fmt|
          @format = {:strftime => fmt} of Symbol => (String | Int32)
        end

        opts.separator ""
        opts.separator "Structured Data Options:"
        opts.on("--field FIELD", "Field index or name to convert. Supports comma-separated list") do |field|
          # Split by comma to support "--field 1,2,3" syntax
          field.split(',').each do |f|
            @fields << f.strip
          end
        end

        opts.on("-d PATTERN", "--delimiter PATTERN", "Field separator (string or /regex/)") do |delim|
          @delimiter = delim
        end

        opts.on("--headers", "First line contains field names") do
          @headers = true
        end

        opts.separator ""
        opts.separator "Other Options:"
        opts.on("--require STRING", "Require external library (placeholder for compatibility)") do |requirement|
          # Crystal doesn't support dynamic requires like Ruby
          # This is a placeholder for compatibility
        end

        opts.on("--color MODE", "Colorize output (auto, always, never)") do |mode|
          unless ["auto", "always", "never"].includes?(mode)
            raise ArgumentError.new("Invalid color mode '#{mode}' (must be auto, always, or never)")
          end
          @color = mode
        end

        opts.on("--verbose", "-v", "Show debug output") do
          @verbose = true
        end

        opts.on("--silent", "-s", "Suppress warnings") do
          @silent = true
        end

        opts.on("--help", "-h", "Show this help") do
          puts opts
          exit
        end
      end

      parser.parse(argv)
    end

    def validate!
      validate_timezone!
      validate_field_mode!
      self
    end

    private def validate_timezone!
      case @zone
      when "utc", "UTC", "local"
        # Valid special timezone keywords
      else
        tz = Zone.find(@zone)
        raise ArgumentError.new("Could not find timezone '#{@zone}'") if tz.nil?
      end
    end

    private def validate_field_mode!
      if !@fields.empty? && @delimiter.empty?
        raise ArgumentError.new("--field requires --delimiter\nExample: zone --field 2 --delimiter ','")
      end

      if @headers && @fields.empty?
        raise ArgumentError.new("--headers requires --field")
      end
    end
  end
end
