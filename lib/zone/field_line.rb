# frozen_string_literal: true

require_relative 'field_mapping'

module Zone
  class FieldLine
    def self.parse(text, delimiter: nil, mapping: nil, logger: nil)
      inferred_delimiter = infer_delimiter(
        text,
        explicit: delimiter,
        logger: logger
      )

      fields = split_line(
        text,
        inferred_delimiter
      )

      new(
        fields: fields,
        delimiter: inferred_delimiter,
        mapping: mapping
      )
    end

    def self.infer_delimiter(line, explicit: nil, logger: nil)
      case [line, explicit]
      in [_, /^\/.*\/$/]
        Regexp.new(explicit[1..-2])
      in [_, String => d]
        d
      in [/,\s+/, nil]
        logger&.debug "Using comma with whitespace as delimiter."
        /,\s*/
      in [/\t/, nil]
        logger&.debug "Using tab as delimiter."
        "\t"
      in [/,/, nil]
        logger&.debug "Using comma as delimiter."
        ','
      else
        logger&.debug "Could not detect delimiter. Using whitespace."
        /\s+/
      end
    end

    def self.split_line(line, delimiter)
      case [line, delimiter]
      in [String, ""]
        [line]
      in [String, String | Regexp]
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
      output_delim = (@delimiter in Regexp) ? "\t" : @delimiter

      case @fields.count
      in 1
        @fields[0]
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
