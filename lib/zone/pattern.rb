# frozen_string_literal: true

require_relative 'timestamp_patterns'

module Zone
  module Pattern
    module_function

    #
    # Process input in pattern mode.
    #
    # Scans each line for timestamp patterns and replaces them with
    # transformed values.
    #
    # @param [Input] input
    #   Input source
    #
    # @param [Output] output
    #   Output destination
    #
    # @param [Proc] transformation
    #   Transformation lambda from Transform.build
    #
    # @param [Logger] logger
    #   Logger instance
    #
    def process(input, output, transformation, logger)
      input.each_line do |line_text|
        # Skip empty lines with warning
        if line_text.empty?
          logger.warn("Could not parse time from empty line")
          next
        end

        matched = false
        result = TimestampPatterns.replace_all(line_text, logger: logger) do |match, _pattern|
          matched = true
          begin
            formatted = transformation.call(match)
            output.colorize_timestamp(formatted)
          rescue StandardError => e
            logger.warn("Could not parse time: #{e.message}")
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
            logger.warn("Could not parse time from: #{result}")
            output.puts(result)
          end
        else
          output.puts(result)
        end
      end
    end
  end
end
