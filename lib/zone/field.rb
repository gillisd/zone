# frozen_string_literal: true

require_relative 'field_line'
require_relative 'field_mapping'

module Zone
  module Field
    module_function

    def process(input, output, transformation, options, logger)
      mapping = build_mapping(input, options)

      input.each_line do |line|
        process_line(line, input.skip_headers?, output, transformation, options, mapping, logger)
      end
    end

    def process_line(line, skip, output, transformation, options, mapping, logger)
      return if skip

      field_line = FieldLine
        .parse(line, delimiter: options.delimiter, mapping: mapping, logger: logger)
        .transform(options.field, &transformation)

      case field_line[options.field]
      in nil
        logger.warn("Field '#{options.field}' not found or out of bounds in line: #{line}")
      in value
        output.puts_highlighted(field_line.to_s, highlight: value)
      end
    end
    private_class_method :process_line

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
