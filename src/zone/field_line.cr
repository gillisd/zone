require 'field_mapping'

module Zone
  class FieldLine
    def self.parse(text, delimiter:, mapping: nil, logger: nil)
      parsed_delimiter = parse_delimiter(delimiter)

      fields = split_line(text, parsed_delimiter)

      new(
        fields: fields,
        delimiter: parsed_delimiter,
        mapping: mapping
      )
    end

    def self.parse_delimiter(delimiter_string)
      case delimiter_string
      in /^\/(.*)\/$/
        # Regex delimiter wrapped in slashes: "/\s+/" -> /\s+/
        Regex.new($1)
      in String => d
        # String delimiter: "," -> ","
        d
      else
        raise ArgumentError, "Invalid delimiter: #{delimiter_string.inspect}"
      end
    end

    def self.split_line(line, delimiter)
      case [line, delimiter]
      in [String, ""]
        [line]
      in [String, String | Regex]
        line.split(delimiter)
      else
        raise ArgumentError, "Invalid delimiter type: #{delimiter.class}"
      end
    end

    def initialize(fields:, delimiter:, mapping: nil)
      @fields = fields.map(&:strip)
      @delimiter = delimiter
      @mapping = mapping || FieldMapping.numeric
    end

    def [](key)
      index = @mapping.resolve(key)
      @fields[index]
    end

    def transform(key, &block)
      index = @mapping.resolve(key)
      @fields[index] = block.call(@fields[index])
      self
    end

    def transform_all(&block)
      @fields.map!(&block)
      self
    end

    def to_s
      output_delim = case @delimiter
      when Regex
        "\t"
      when ","
        "\t"
      else
        @delimiter
      end

      case @fields.count
      in 1
        @fields[0].to_s
      else
        @fields.join(output_delim)
      end
    end

    def to_a
      @fields.dup
    end

    def to_h
      return {} unless @mapping.has_names?

      @mapping.names.zip(@fields).to_h
    end

    def fields
      @fields.dup
    end
  end
end
