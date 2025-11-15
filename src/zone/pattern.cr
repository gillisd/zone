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
      if line.empty?
        # logger.warn("Could not parse time from empty line") if from_arguments
        output.puts(line) unless from_arguments
      else
        result = replace_timestamps(line, output, transformation, logger)

        if result == line && from_arguments
          parse_as_argument(line, output, transformation)
        elsif result == line
          output.puts(line)
        else
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
      formatted = transformation.call(match)
      formatted ? output.colorize_timestamp(formatted) : match
    rescue ex : Exception
      # logger.warn("Could not parse time: #{ex.message}")
      match
    end

    private def parse_as_argument(text : String, output : Output, transformation : Proc(String, String?))
      formatted = transformation.call(text)
      raise ArgumentError.new("Could not parse time '#{text}'") if formatted.nil?

      output.puts(output.colorize_timestamp(formatted))
    end
  end
end
