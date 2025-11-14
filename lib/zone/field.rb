# frozen_string_literal: true

require_relative 'field_line'
require_relative 'field_mapping'

module Zone
  module Field
    module_function

    #
    # Process input in field mode.
    #
    # Extracts specific field from delimited data and transforms it.
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
    # @param [Options] options
    #   Parsed options (needs field, delimiter, headers)
    #
    # @param [Logger] logger
    #   Logger instance
    #
    def process(input, output, transformation, options, logger)
      mapping = build_mapping(input, options)

      input.each_line do |line_text|
        next if input.skip_headers?

        field_line = FieldLine.parse(
          line_text,
          delimiter: options.delimiter,
          mapping: mapping,
          logger: logger
        )

        field_line.transform(options.field, &transformation)

        transformed_value = field_line[options.field]
        if transformed_value
          output.puts_highlighted(field_line.to_s, highlight: transformed_value)
        else
          logger.warn("Field '#{options.field}' not found or out of bounds in line: #{line_text}")
        end
      end
    end

    #
    # Build field mapping from headers if needed.
    #
    # @param [Input] input
    # @param [Options] options
    #
    # @return [FieldMapping]
    #
    def build_mapping(input, options)
      return FieldMapping.numeric unless options.headers

      input.mark_skip_headers!
      header_line = input.each_line.first

      parsed = FieldLine.parse_delimiter(options.delimiter)
      fields = FieldLine.split_line(header_line, parsed)

      FieldMapping.from_fields(fields.map(&:strip))
    end
    private_class_method :build_mapping
  end
end
