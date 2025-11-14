# frozen_string_literal: true

require 'optparse'

module Zone
  class Options < OptionParser
    attr_reader :field, :delimiter, :zone, :format, :color, :headers
    attr_accessor :verbose

    def initialize
      super

      @field = nil
      @delimiter = nil
      @zone = 'local'
      @format = { pretty: 1 }
      @color = 'auto'
      @headers = false
      @verbose = false

      setup_options
    end

    private

    def setup_options
      self.banner = "Usage: zone [options] [timestamps...]"

      separator ""
      separator "Modes:"
      separator "  Pattern Mode (default): Finds and converts timestamps in arbitrary text"
      separator "    Example: echo 'Event at 2025-01-15T10:30:00Z' | zone"
      separator ""
      separator "  Field Mode: Converts specific field in delimited data (requires --field and --delimiter)"
      separator "    Example: echo 'alice,1736937000,active' | zone --field 2 --delimiter ','"

      separator ""
      separator "Output Formats:"
      on '--iso8601', 'Output in ISO 8601' do
        @format = :to_iso8601
      end

      on '-f', '--strftime FORMAT', 'Output format using strftime' do |fmt|
        @format = { strftime: fmt }
      end

      on '-p', '--pretty [STYLE]', Integer, 'Pretty format (1=12hr, 2=24hr, 3=ISO-compact, default: 1)' do |style|
        @format = { pretty: style || 1 }
      end

      on '--unix', 'Output as Unix timestamp' do
        @format = :to_unix
      end

      separator ""
      separator "Timezones:"
      on '--require STRING', 'Require external library like "active_support" for more powerful parsing' do |requirement|
        require requirement
      end

      on '--zone TZ', '-z', 'Convert to time zone (default: local)' do |tz|
        @zone = tz
      end

      on '--local', 'Convert to local time zone (alias for --zone local)' do
        @zone = 'local'
      end

      on '--utc', 'Convert to UTC time zone (alias for --zone UTC)' do
        @zone = 'utc'
      end

      separator ""
      separator "Field Mode Options:"
      on '--field FIELD', String, 'Field index or name to convert (requires --delimiter)' do |field|
        @field = field
      end

      on '-d', '--delimiter PATTERN', 'Field separator (string or /regex/, required for --field)' do |delim|
        @delimiter = delim
      end

      on '--headers', 'Skip first line as headers (requires --field)' do
        @headers = true
      end

      separator ""
      separator "Other:"
      on '--color MODE', ['auto', 'always', 'never'], 'Colorize output (auto, always, never, default: auto)' do |mode|
        @color = mode
      end

      on '--verbose', '-v', 'Enable verbose/debug output' do
        @verbose = true
      end

      on '--help', '-h', 'Show this help message' do
        puts self
        exit
      end
    end
  end
end
