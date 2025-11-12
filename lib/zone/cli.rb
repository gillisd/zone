# frozen_string_literal: true

require 'logger'
require 'optparse'
require_relative 'timestamp'
require_relative 'field_line'
require_relative 'field_mapping'

module Zone
  class CLI
    COLORS = {
      reset: "\e[0m",
      bold: "\e[1m",
      cyan: "\e[36m",
      yellow: "\e[33m",
      red: "\e[31m",
      gray: "\e[90m"
    }.freeze

    def self.run(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv
      @options = {
        delimiter: nil,
        strftime: nil,
        iso8601: false,
        pretty: false,
        headers: false,
        unix: false,
        field: 1,
        zone: nil,
        utc: false,
        local: false
      }
    end

    def run
      parse_options!
      setup_logger!
      setup_active_support!
      validate_timezone!

      transformation = build_transformation
      mapping = build_mapping

      process_lines(
        transformation,
        mapping
      )
    rescue Errno::ENOENT => e
      filename = e.message[/@.*- (.*)/, 1]
      $stderr.puts "Error: Could not parse time '#{filename}'"
      exit 1
    rescue ArgumentError, StandardError => e
      $stderr.puts "Error: #{e.message}"
      exit 1
    end

    private

    def validate_timezone!
      zone_name = determine_zone

      return if ['utc', 'UTC', 'local'].include?(zone_name)

      tz = Zone.find(zone_name)
      raise ArgumentError, "Could not find timezone '#{zone_name}'" if tz.nil?
    end

    def parse_options!
      parser = OptionParser.new do |p|
        p.banner = "Usage: zone [options] [timestamps...]"
        p.separator ""
        p.separator "Output Formats:"
        p.on '--iso8601', 'Output in ISO 8601 (default: true)'
        p.on '--strftime FORMAT', '-f', 'Output format using strftime (default: none)'
        p.on '--pretty', '-p', 'Output in pretty format (e.g., "Jan 02 - 03:04 PM")'
        p.on '--unix', 'Output as Unix timestamp (default: false)'

        p.separator ""
        p.separator "Timezones:"
        p.on '--require STRING', 'Require external library like "active_support" for more powerful parsing' do |requirement|
          require requirement
        end
        p.on '--zone TZ', '-z', 'Convert to time zone (default: UTC)'
        p.on '--local', 'Convert to local time zone (alias for --zone local)'
        p.on '--utc', 'Convert to UTC time zone (alias for --zone UTC)'

        p.separator ""
        p.separator "Data Processing:"
        p.on '--field FIELD', '-F N', String, 'Field index or field name to convert (default: 1)'
        p.on '--delimiter PATTERN', '-d', 'Field delimiter (default: space)'
        p.on '--headers', 'Skip the first line as headers'

        p.separator ""
        p.separator "Other:"
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
          color = case severity
          when "INFO"  then COLORS[:cyan]
          when "WARN"  then COLORS[:yellow]
          when "ERROR" then COLORS[:red]
          else COLORS[:gray]
          end

          prefix = case severity
          when "INFO"  then "→"
          when "WARN"  then "⚠"
          when "ERROR" then "✗"
          when "DEBUG" then "DEBUG:"
          else "?"
          end

          "#{color}#{prefix} #{message}#{COLORS[:reset]}\n"
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
        in :to_iso8601 | :to_unix | :to_pretty
          converted.send(format_method)
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
        'utc'
      end
    end

    def determine_format_method
      case @options
      in { strftime: String => fmt }
        { strftime: fmt }
      in { unix: true }
        :to_unix
      in { pretty: true }
        :to_pretty
      else
        :to_iso8601
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
      use_field_processing = needs_field_processing?

      input.each do |line_text|
        if use_field_processing
          field_line = FieldLine.parse(
            line_text,
            delimiter: @options[:delimiter],
            mapping: mapping,
            logger: @logger
          )

          field_line.transform(@options[:field], &transformation)

          # Output only the transformed field
          transformed_value = field_line[@options[:field]]
          $stdout.puts transformed_value unless transformed_value.nil?
        else
          # Treat entire line as timestamp
          result = transformation.call(line_text.strip)
          $stdout.puts result unless result.nil?
        end
      end
    end

    def needs_field_processing?
      @options[:delimiter] || @options[:headers] || @options[:field] != 1
    end
  end
end
