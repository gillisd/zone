require 'timestamp_patterns'

module Zone
  module Pattern
    module_function

    def process(input, output, transformation, logger)
      input.each_line do |line|
        process_line(line, input.from_arguments?, output, transformation, logger)
      end
    end

    def process_line(line, from_arguments, output, transformation, logger)
      case line
      in ""
        logger.warn("Could not parse time from empty line") if from_arguments
        output.puts(line) unless from_arguments
      else
        result = replace_timestamps(line, output, transformation, logger)

        case [result == line, from_arguments]
        in [true, true]
          parse_as_argument(line, output, transformation)
        in [true, false]
          output.puts(line)
        in [false, _]
          output.puts(result)
        end
      end
    end
    private_class_method :process_line

    def replace_timestamps(line, output, transformation, logger)
      TimestampPatterns.replace_all(line, logger: logger) do |match, _pattern|
        transform_timestamp(match, output, transformation, logger)
      end
    end
    private_class_method :replace_timestamps

    def transform_timestamp(match, output, transformation, logger)
      formatted = transformation.call(match)
      output.colorize_timestamp(formatted)
    rescue Exception => e
      logger.warn("Could not parse time: #{e.message}")
      match
    end
    private_class_method :transform_timestamp

    def parse_as_argument(text, output, transformation)
      formatted = transformation.call(text)
      raise ArgumentError, "Could not parse time '#{text}'" if formatted.nil?

      output.puts(output.colorize_timestamp(formatted))
    end
    private_class_method :parse_as_argument
  end
end
