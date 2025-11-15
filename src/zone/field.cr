require 'field_line'
require 'field_mapping'

module Zone
  module Field
    module_function

    def process(input, output, transformation, options, logger)
      mapping, header_line = build_mapping(input, options)

      # Output header line if present
      output.puts(header_line) if header_line

      input.each_line do |line|
        process_line(line, input.skip_headers?, output, transformation, options, mapping, logger)
      end
    end

    def process_line(line, skip, output, transformation, options, mapping, logger)
      return if skip

      field_line = FieldLine.parse(line, delimiter: options.delimiter, mapping: mapping, logger: logger)

      # Check if field exists before transforming
      original_value = field_line[options.field]
      if original_value.nil?
        logger.warn("Field '#{options.field}' not found or out of bounds in line: #{line}")
        return
      end

      # Transform the field
      field_line.transform(options.field, &transformation)

      # Get transformed value
      transformed_value = field_line[options.field]
      if transformed_value.nil?
        logger.warn("Could not parse timestamp in field '#{options.field}': #{original_value.inspect}")
        return
      end

      output.puts_highlighted(field_line.to_s, highlight: transformed_value)
    end
    private_class_method :process_line

    def build_mapping(input, options)
      return [FieldMapping.numeric, nil] unless options.headers

      input.mark_skip_headers!
      header_line = input.each_line.first

      parsed = FieldLine.parse_delimiter(options.delimiter)
      fields = FieldLine.split_line(header_line, parsed)

      # Format header line the same way as data lines
      formatted_header = FieldLine.new(
        fields: fields,
        delimiter: parsed,
        mapping: FieldMapping.numeric
      ).to_s

      [FieldMapping.from_fields(fields.map(&:strip)), formatted_header]
    end
    private_class_method :build_mapping
  end
end
