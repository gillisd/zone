require "./field_mapping"

module Zone
  class FieldLine
    @fields : Array(String)
    def self.parse(text : String, delimiter : String, mapping : FieldMapping? = nil, logger : Log? = nil) : FieldLine
      parsed_delimiter = parse_delimiter(delimiter)

      fields = split_line(text, parsed_delimiter)

      new(
        fields: fields,
        delimiter: parsed_delimiter,
        mapping: mapping
      )
    end

    def self.parse_delimiter(delimiter_string : String) : String | Regex
      if delimiter_string.starts_with?("/") && delimiter_string.ends_with?("/")
        # Regex delimiter wrapped in slashes: "/\s+/" -> /\s+/
        pattern = delimiter_string[1..-2]
        Regex.new(pattern)
      else
        # String delimiter: "," -> ","
        delimiter_string
      end
    end

    def self.split_line(line : String, delimiter : String | Regex) : Array(String)
      if line.empty? && delimiter.is_a?(String) && delimiter.empty?
        [line]
      else
        line.split(delimiter)
      end
    end

    def initialize(fields : Array(String), @delimiter : String | Regex, mapping : FieldMapping? = nil)
      @fields = fields.map(&.strip)
      @mapping = mapping || FieldMapping.numeric
    end

    def [](key : String | Int32) : String?
      index = @mapping.resolve(key)
      @fields[index]?
    end

    def transform(key : String | Int32, &block : String -> String?) : self
      index = @mapping.resolve(key)
      if (value = @fields[index]?)
        @fields[index] = block.call(value) || value
      end
      self
    end

    def transform_all(&block : String -> String?) : self
      @fields.map! do |field|
        block.call(field) || field
      end
      self
    end

    def to_s : String
      output_delim = case @delimiter
      when Regex
        # Use tab for regex delimiters (can't reconstruct original)
        "\t"
      else
        # Use the actual input delimiter for output
        @delimiter.as(String)
      end

      case @fields.size
      when 1
        @fields[0].to_s
      else
        # Quote fields that contain the delimiter
        quoted_fields = @fields.map do |field|
          if needs_quoting?(field, output_delim)
            quote_field(field)
          else
            field
          end
        end
        quoted_fields.join(output_delim)
      end
    end

    private def needs_quoting?(field : String, delimiter : String) : Bool
      # Check if field contains the delimiter
      # For regex delimiters (tab), check for tab, space, or common whitespace
      if delimiter == "\t"
        field.includes?(' ') || field.includes?('\t')
      else
        field.includes?(delimiter)
      end
    end

    private def quote_field(field : String) : String
      # Escape any existing quotes and wrap in quotes
      escaped = field.gsub('"', "\"\"")
      "\"#{escaped}\""
    end

    def to_a : Array(String)
      @fields.dup
    end

    def to_h : Hash(String, String)
      return {} of String => String unless @mapping.has_names?

      result = {} of String => String
      @mapping.names.each_with_index do |name, idx|
        result[name] = @fields[idx]
      end
      result
    end

    def fields : Array(String)
      @fields.dup
    end
  end
end
