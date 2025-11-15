require "./field_line"
require "./field_mapping"

module Zone
  module Field
    extend self

    def process(input, output, transformation, options, logger)
      mapping, header_line = build_mapping(input, options)

      # Output header line if present
      output.puts(header_line) if header_line.is_a?(String)

      input.each_line do |line|
        process_line(line, input.skip_headers?, output, transformation, options, mapping, logger)
      end
    end

    def process_line(line, skip, output, transformation, options, mapping, logger)
      return if skip

      delimiter_str = options.delimiter
      return unless delimiter_str

      field_key = options.field
      return unless field_key

      field_line = FieldLine.parse(line, delimiter: delimiter_str, mapping: mapping, logger: logger)

      # Check if field exists before transforming
      original_value = field_line[field_key]
      if original_value.nil?
        logger.warn { "Field '#{field_key}' not found or out of bounds in line: #{line}" }
        return
      end

      # Transform the field
      field_line.transform(field_key) do |value|
        result = transformation.call(value)
        if result.nil?
          logger.warn { "Could not parse time '#{value}'" }
        end
        result
      end

      # Output the line with the field (transformed or original)
      transformed = field_line[field_key]
      output.puts_highlighted(field_line.to_s, highlight: transformed || original_value)
    end

    def build_mapping(input, options) : Tuple(FieldMapping, String?)
      return {FieldMapping.numeric, nil} unless options.headers

      input.mark_skip_headers!
      header_line = ""
      found = false
      input.each_line do |line|
        unless found
          header_line = line
          found = true
        end
      end

      delimiter_str = options.delimiter
      return {FieldMapping.numeric, nil} if delimiter_str.nil?

      parsed = FieldLine.parse_delimiter(delimiter_str)
      fields = FieldLine.split_line(header_line, parsed)

      # Format header line the same way as data lines
      formatted_header = FieldLine.new(
        fields: fields,
        delimiter: parsed,
        mapping: FieldMapping.numeric
      ).to_s

      {FieldMapping.from_fields(fields.map { |f| f.strip }), formatted_header}
    end
  end
end
