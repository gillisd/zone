# frozen_string_literal: true

require 'logger'
require_relative 'options'
require_relative 'input'
require_relative 'output'
require_relative 'transform'
require_relative 'field_line'
require_relative 'field_mapping'
require_relative 'timestamp_patterns'
require_relative 'colors'

module Zone
  class CLI
    def self.run(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv
    end

    def run
      options = Options.new
      options.parse!(@argv)

      setup_logger!(options.verbose)
      setup_active_support!
      validate_timezone!(options.zone)
      validate_field_mode!(options)

      input = Input.new(@argv)
      output = Output.new(color_mode: options.color)
      transformation = Transform.build(zone: options.zone, format: options.format)

      if options.field
        process_field_mode(input, output, transformation, options)
      else
        process_pattern_mode(input, output, transformation)
      end
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption, OptionParser::InvalidArgument => e
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{e.message}"
      $stderr.puts "Run 'zone --help' for usage information."
      exit 1
    rescue ArgumentError, StandardError => e
      message = e.message.gsub(/'([^']+)'/) do
        "'#{Colors.colors($stderr).bold($1)}'"
      end
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{message}"
      exit 1
    end

    private

    def setup_logger!(verbose)
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
        l.level = verbose ? Logger::DEBUG : Logger::WARN
      end
    end

    def setup_active_support!
      if defined?(ActiveSupport)
        ActiveSupport.to_time_preserves_timezone = true
      end
    end

    def validate_timezone!(zone_name)
      return if ['utc', 'UTC', 'local'].include?(zone_name)

      tz = Zone.find(zone_name)
      raise ArgumentError, "Could not find timezone '#{zone_name}'" if tz.nil?
    end

    def validate_field_mode!(options)
      if options.field && !options.delimiter
        raise ArgumentError, "--field requires --delimiter\nExample: zone --field 2 --delimiter ','"
      end

      if options.headers && !options.field
        raise ArgumentError, "--headers requires --field"
      end
    end

    def process_field_mode(input, output, transformation, options)
      mapping = build_mapping(input, options)

      input.each_line do |line_text|
        next if input.skip_headers?

        field_line = FieldLine.parse(
          line_text,
          delimiter: options.delimiter,
          mapping: mapping,
          logger: @logger
        )

        field_line.transform(options.field, &transformation)

        transformed_value = field_line[options.field]
        if transformed_value
          output.puts_highlighted(field_line.to_s, highlight: transformed_value)
        else
          @logger.warn("Field '#{options.field}' not found or out of bounds in line: #{line_text}")
        end
      end
    end

    def process_pattern_mode(input, output, transformation)
      input.each_line do |line_text|
        # Skip empty lines with warning
        if line_text.empty?
          @logger.warn("Could not parse time from empty line")
          next
        end

        matched = false
        result = TimestampPatterns.replace_all(line_text, logger: @logger) do |match, _pattern|
          matched = true
          begin
            formatted = transformation.call(match)
            output.colorize_timestamp(formatted)
          rescue StandardError => e
            @logger.warn("Could not parse time: #{e.message}")
            match
          end
        end

        # If no pattern matched, handle based on input source
        if !matched
          if input.from_arguments?
            # Arguments: try to parse directly, error if fails
            formatted = transformation.call(result)
            if formatted.nil?
              raise ArgumentError, "Could not parse time '#{result}'"
            end
            colored = output.colorize_timestamp(formatted)
            output.puts(colored)
          else
            # Piped input: warn and pass through unchanged
            @logger.warn("Could not parse time from: #{result}")
            output.puts(result)
          end
        else
          output.puts(result)
        end
      end
    end

    def build_mapping(input, options)
      return FieldMapping.numeric unless options.headers

      input.mark_skip_headers!
      header_line = input.each_line.first

      parsed = FieldLine.parse_delimiter(options.delimiter)
      fields = FieldLine.split_line(header_line, parsed)

      FieldMapping.from_fields(fields.map(&:strip))
    end
  end
end
