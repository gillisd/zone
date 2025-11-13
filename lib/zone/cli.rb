# frozen_string_literal: true

require 'logger'
require 'optparse'
require_relative 'timestamp'
require_relative 'field_line'
require_relative 'field_mapping'
require_relative 'colors'
require_relative 'timestamp_patterns'

module Zone
  class CLI
    def self.run(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv
      @options = {
        delimiter: nil,
        strftime: nil,
        iso8601: false,
        pretty: nil,
        headers: false,
        unix: false,
        field: nil,
        zone: nil,
        utc: false,
        local: false,
        color: 'auto'
      }
    end

    def run
      parse_options!
      setup_logger!
      setup_active_support!
      validate_timezone!
      validate_field_mode!

      transformation = build_transformation
      mapping = build_mapping

      process_lines(
        transformation,
        mapping
      )
    rescue OptionParser::MissingArgument => e
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{e.message}"
      $stderr.puts "Run 'zone --help' for usage information."
      exit 1
    rescue OptionParser::InvalidOption => e
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{e.message}"
      $stderr.puts "Run 'zone --help' for usage information."
      exit 1
    rescue Errno::ENOENT => e
      filename = e.message[/@.*- (.*)/, 1]
      highlighted = Colors.colors($stderr).bold(filename)
      $stderr.puts Colors.colors($stderr).red("Error:") + " Could not parse time '#{highlighted}'"
      exit 1
    rescue ArgumentError, StandardError => e
      # Highlight the value within the error message
      message = e.message.gsub(/'([^']+)'/) do
        "'#{Colors.colors($stderr).bold($1)}'"
      end
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{message}"
      exit 1
    end

    private

    def validate_timezone!
      zone_name = determine_zone

      return if ['utc', 'UTC', 'local'].include?(zone_name)

      tz = Zone.find(zone_name)
      raise ArgumentError, "Could not find timezone '#{zone_name}'" if tz.nil?
    end

    def validate_field_mode!
      if @options[:field] && !@options[:delimiter]
        raise ArgumentError, "--field requires --delimiter\nExample: zone --field 2 --delimiter ','"
      end

      if @options[:headers] && !@options[:field]
        raise ArgumentError, "--headers requires --field"
      end
    end

    def parse_options!
      parser = OptionParser.new do |p|
        p.banner = "Usage: zone [options] [timestamps...]"
        p.separator ""
        p.separator "Modes:"
        p.separator "  Pattern Mode (default): Finds and converts timestamps in arbitrary text"
        p.separator "    Example: echo 'Event at 2025-01-15T10:30:00Z' | zone"
        p.separator ""
        p.separator "  Field Mode: Converts specific field in delimited data (requires --field and --delimiter)"
        p.separator "    Example: echo 'alice,1736937000,active' | zone --field 2 --delimiter ','"
        p.separator ""
        p.separator "Output Formats:"
        p.on '--iso8601', 'Output in ISO 8601'
        p.on '-f', '--strftime FORMAT', 'Output format using strftime'
        p.on '-p', '--pretty [STYLE]', Integer, 'Pretty format (1=12hr, 2=24hr, 3=ISO-compact, default: 1)'
        p.on '--unix', 'Output as Unix timestamp'

        p.separator ""
        p.separator "Timezones:"
        p.on '--require STRING', 'Require external library like "active_support" for more powerful parsing' do |requirement|
          require requirement
        end
        p.on '--zone TZ', '-z', 'Convert to time zone (default: UTC)'
        p.on '--local', 'Convert to local time zone (alias for --zone local)'
        p.on '--utc', 'Convert to UTC time zone (alias for --zone UTC)'

        p.separator ""
        p.separator "Field Mode Options:"
        p.on '--field FIELD', String, 'Field index or name to convert (requires --delimiter)'
        p.on '-d', '--delimiter PATTERN', 'Field separator (string or /regex/, required for --field)'
        p.on '--headers', 'Skip first line as headers (requires --field)'

        p.separator ""
        p.separator "Other:"
        p.on '--color MODE', ['auto', 'always', 'never'], 'Colorize output (auto, always, never, default: auto)'
        p.on '--verbose', '-v', 'Enable verbose/debug output'
        p.on '--help', '-h', 'Show this help message' do
          puts p
          exit
        end
      end

      parser.parse!(
        @argv,
        into: @options
      )
    end

    def setup_logger!
      @logger = Logger.new($stderr).tap do |l|
        l.formatter = ->(severity, _datetime, _progname, message) {
          prefix = case severity
          when "INFO"  then "→"
          when "WARN"  then "⚠"
          when "ERROR" then "✗"
          when "DEBUG" then "DEBUG:"
          else "?"
          end

          formatted = "#{prefix} #{message}"

          colored = case severity
          when "INFO"  then Colors.colors($stderr).cyan(formatted)
          when "WARN"  then Colors.colors($stderr).yellow(formatted)
          when "ERROR" then Colors.colors($stderr).red(formatted)
          else formatted
          end

          "#{colored}\n"
        }
        verbose = @options.delete(:verbose)
        l.level = verbose ? Logger::DEBUG : Logger::WARN
      end
    end

    def setup_active_support!
      if defined?(ActiveSupport)
        ActiveSupport.to_time_preserves_timezone = true
      end
    end

    def build_transformation
      zone_name = determine_zone
      format_method = determine_format_method

      ->(value) do
        timestamp = Timestamp.parse(value)

        converted = case zone_name
        in 'utc' | 'UTC'
          timestamp.in_utc
        in 'local'
          timestamp.in_local
        else
          timestamp.in_zone(zone_name)
        end

        case format_method
        in :to_iso8601 | :to_unix
          converted.send(format_method)
        in { pretty: Integer => style }
          converted.to_pretty(style)
        in { strftime: String => fmt }
          converted.strftime(fmt)
        end
      rescue ArgumentError => e
        @logger.warn "Warning: #{e.message}. Skipping."
        nil
      end
    end

    def determine_zone
      case @options
      in { utc: true }
        'utc'
      in { local: true }
        'local'
      in { zone: String => z }
        z
      else
        'local'
      end
    end

    def determine_format_method
      case @options
      in { strftime: String => fmt }
        { strftime: fmt }
      in { unix: true }
        :to_unix
      in { iso8601: true }
        :to_iso8601
      in { pretty: Integer => style }
        { pretty: style }
      else
        { pretty: 1 }
      end
    end

    def build_mapping
      input = build_input_source

      if @options[:headers]
        header_line = input.next
        fields = FieldLine.split_line(
          header_line,
          FieldLine.infer_delimiter(
            header_line,
            explicit: @options[:delimiter],
            logger: @logger
          )
        )

        FieldMapping.from_fields(fields.map(&:strip))
      else
        FieldMapping.numeric
      end
    end

    def build_input_source
      @input_source ||= begin
        timestamps = detect_timestamp_arguments

        if timestamps.any?
          timestamps
        elsif @argv.any? || !STDIN.tty?
          ARGF.each_line(chomp: true)
        else
          [Time.now.to_s]
        end
      end
    end

    def detect_timestamp_arguments
      if @argv.any? && @argv.all? { |arg| arg.match?(/^\d|[A-Z][a-z]{2}|:/) }
        @logger.debug "Treating arguments as timestamp strings."
        timestamps = @argv.dup
        @argv.clear
        timestamps
      else
        []
      end
    end

    def process_lines(transformation, mapping)
      input = build_input_source

      if @options[:field]
        # Field mode: split fields, transform specific field, rejoin
        process_field_mode(input, transformation, mapping)
      else
        # Pattern mode (default): find and replace timestamps in text
        process_pattern_mode(input, transformation)
      end
    end

    def colorize(stream)
      case @options[:color]
      when 'always'
        Colors::ANSI
      when 'never'
        Colors::PlainText
      when 'auto'
        Colors.colors(stream)
      end
    end

    def process_field_mode(input, transformation, mapping)
      colors = colorize($stdout)

      input.each do |line_text|
        field_line = FieldLine.parse(
          line_text,
          delimiter: @options[:delimiter],
          mapping: mapping,
          logger: @logger
        )

        field_line.transform(@options[:field], &transformation)

        # Output full line with transformed field (skip if transformation failed)
        transformed_value = field_line[@options[:field]]
        if transformed_value
          # Colorize the transformed field in the output
          output_line = field_line.to_s.sub(transformed_value, colors.cyan(transformed_value))
          $stdout.puts output_line
        end
      end
    end

    def process_pattern_mode(input, transformation)
      colors = colorize($stdout)

      input.each do |line_text|
        result = TimestampPatterns.replace_all(line_text, logger: @logger) do |match, pattern|
          begin
            formatted = transformation.call(match)
            colors.cyan(formatted)
          rescue StandardError => e
            @logger.debug("Failed to transform '#{match}': #{e.message}")
            match
          end
        end

        $stdout.puts result
      end
    end
  end
end
