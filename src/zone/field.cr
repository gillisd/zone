require "./field_line"
require "./field_mapping"

module Zone
  module Field
    extend self

    def process(input : Input, output : Output, transformation : Proc(String, String?), options : Options, logger : Log)
      mapping, header_line = build_mapping(input, options)

      # Output header line if present
      output.puts(header_line) if header_line

      input.each_line do |line|
        process_line(line, input.skip_headers?, output, transformation, options, mapping, logger)
      end
    end

    private def process_line(line : String, skip : Bool, output : Output, transformation : Proc(String, String?), options : Options, mapping : FieldMapping, logger : Log)
      return if skip

      field = options.field
      return unless field  # Should not happen as field mode requires field option

      field_line = FieldLine.parse(line, delimiter: options.delimiter, mapping: mapping, logger: logger)

      # Check if field exists before transforming
      original_value = field_line[field]
      if original_value.nil?
        logger.warn { "Field '#{field}' not found or out of bounds in line: #{line}" }
        return
      end

      # Transform the field
      field_line.transform(field, &transformation)

      # Get transformed value
      transformed_value = field_line[field]
      if transformed_value.nil?
        logger.warn { "Could not parse timestamp in field '#{field}': #{original_value.inspect}" }
        return
      end

      output.puts_highlighted(field_line.to_s, highlight: transformed_value)
    end

    private def build_mapping(input : Input, options : Options) : Tuple(FieldMapping, String?)
      return {FieldMapping.numeric, nil} unless options.headers

      input.mark_skip_headers!
      header_line = input.each_line.first?

      return {FieldMapping.numeric, nil} unless header_line

      parsed = FieldLine.parse_delimiter(options.delimiter)
      fields = FieldLine.split_line(header_line, parsed)

      # Format header line the same way as data lines
      formatted_header = FieldLine.new(
        fields: fields,
        delimiter: parsed,
        mapping: FieldMapping.numeric
      ).to_s

      {FieldMapping.from_fields(fields.map(&.strip)), formatted_header}
    end
  end
end
