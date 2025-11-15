require "./timestamp_patterns"

module Zone
  module Pattern
    extend self

    def process(input : Input, output : Output, transformation : Proc(String, String?), logger)
      input.each_line do |line|
        process_line(line, input.from_arguments?, output, transformation, logger)
      end
    end

    private def process_line(line : String, from_arguments : Bool, output : Output, transformation : Proc(String, String?), logger)
      logger.debug { "Processing line: #{line.inspect}" } if logger

      if line.empty?
        output.puts(line) unless from_arguments
      else
        result = replace_timestamps(line, output, transformation, logger)

        if result == line && from_arguments
          logger.debug { "No pattern match, parsing as direct argument" } if logger
          parse_as_argument(line, output, transformation)
        elsif result == line
          output.puts(line)
        else
          logger.debug { "Replaced timestamps in line" } if logger
          output.puts(result)
        end
      end
    end

    private def replace_timestamps(line : String, output : Output, transformation : Proc(String, String?), logger) : String
      TimestampPatterns.replace_all(line, logger: logger) do |match, _pattern|
        transform_timestamp(match, output, transformation, logger)
      end
    end

    private def transform_timestamp(match : String, output : Output, transformation : Proc(String, String?), logger) : String
      logger.debug { "Transforming timestamp: #{match}" } if logger
      formatted = transformation.call(match)
      if formatted
        logger.debug { "Transformed to: #{formatted}" } if logger
        output.colorize_timestamp(formatted)
      else
        match
      end
    rescue ex : Exception
      logger.warn { "Could not parse time: #{ex.message}" } if logger
      match
    end

    private def parse_as_argument(text : String, output : Output, transformation : Proc(String, String?))
      formatted = transformation.call(text)
      raise ArgumentError.new("Could not parse time '#{text}'") if formatted.nil?

      output.puts(output.colorize_timestamp(formatted))
    end
  end
end
