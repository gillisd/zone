require "option_parser"

module Zone
  class Options
    property field : String?
    property delimiter : String
    property zone : String
    property format : Symbol | Hash(Symbol, String | Int32)
    property color : String
    property headers : Bool
    property verbose : Bool

    def initialize
      @field = nil
      @delimiter = ""
      @zone = "local"
      @format = {:pretty => 1} of Symbol => (String | Int32)
      @color = "auto"
      @headers = false
      @verbose = false
    end

    def parse!(argv : Array(String))
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: zone [options] [timestamps...]"

        opts.separator ""
        opts.separator "Modes:"
        opts.separator "  Pattern Mode (default): Finds and converts timestamps in arbitrary text"
        opts.separator "    Example: echo 'Event at 2025-01-15T10:30:00Z' | zone"
        opts.separator ""
        opts.separator "  Field Mode: Converts specific field in delimited data (requires --field and --delimiter)"
        opts.separator "    Example: echo 'alice,1736937000,active' | zone --field 2 --delimiter ','"

        opts.separator ""
        opts.separator "Output Formats:"
        opts.on("--iso8601", "Output in ISO 8601") do
          @format = :to_iso8601
        end

        opts.on("-f FORMAT", "--strftime FORMAT", "Output format using strftime") do |fmt|
          @format = {:strftime => fmt} of Symbol => (String | Int32)
        end

        opts.on("-p [STYLE]", "--pretty [STYLE]", "Pretty format (1=12hr, 2=24hr, 3=ISO-compact, default: 1)") do |style|
          style_int = (style.nil? || style.empty?) ? 1 : style.to_i
          unless [1, 2, 3].includes?(style_int)
            raise ArgumentError.new("Invalid pretty format -p#{style_int} (must be 1, 2, or 3)")
          end
          @format = {:pretty => style_int} of Symbol => (String | Int32)
        end

        opts.on("--unix", "Output as Unix timestamp") do
          @format = :to_unix
        end

        opts.separator ""
        opts.separator "Timezones:"
        opts.on("--require STRING", "Require external library (placeholder for compatibility)") do |requirement|
          # Crystal doesn't support dynamic requires like Ruby
          # This is a placeholder for compatibility
        end

        opts.on("--zone TZ", "-z", "Convert to time zone (default: local)") do |tz|
          @zone = tz
        end

        opts.on("--local", "Convert to local time zone (alias for --zone local)") do
          @zone = "local"
        end

        opts.on("--utc", "Convert to UTC time zone (alias for --zone UTC)") do
          @zone = "utc"
        end

        opts.separator ""
        opts.separator "Field Mode Options:"
        opts.on("--field FIELD", "Field index or name to convert (requires --delimiter)") do |field|
          @field = field
        end

        opts.on("-d PATTERN", "--delimiter PATTERN", "Field separator (string or /regex/, required for --field)") do |delim|
          @delimiter = delim
        end

        opts.on("--headers", "Skip first line as headers (requires --field)") do
          @headers = true
        end

        opts.separator ""
        opts.separator "Other:"
        opts.on("--color MODE", "Colorize output (auto, always, never, default: auto)") do |mode|
          unless ["auto", "always", "never"].includes?(mode)
            raise ArgumentError.new("Invalid color mode '#{mode}' (must be auto, always, or never)")
          end
          @color = mode
        end

        opts.on("--verbose", "-v", "Enable verbose/debug output") do
          @verbose = true
        end

        opts.on("--help", "-h", "Show this help message") do
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
      if @field && @delimiter.empty?
        raise ArgumentError.new("--field requires --delimiter\nExample: zone --field 2 --delimiter ','")
      end

      if @headers && !@field
        raise ArgumentError.new("--headers requires --field")
      end
    end
  end
end
