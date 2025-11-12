# frozen_string_literal: true

module Zone
  class FieldMapping
    def self.from_fields(fields)
      name_to_index = fields.each_with_index.to_h
      new(name_to_index: name_to_index)
    end

    def self.numeric
      new(name_to_index: nil)
    end

    def initialize(name_to_index:)
      @name_to_index = name_to_index
    end

    def resolve(key)
      case key
      in String => name if name.match?(/^\d+$/)
        # Numeric string - convert to integer and resolve
        name.to_i - 1
      in String => name
        @name_to_index&.fetch(name) do
          raise KeyError, "Field '#{name}' not found in mapping"
        end
      in Integer => index
        # Convert 1-based user input to 0-based array index
        index - 1
      else
        raise ArgumentError, "Key must be String or Integer, got #{key.class}"
      end
    end

    def [](key)
      resolve(key)
    end

    def names
      @name_to_index&.keys || []
    end

    def has_names?
      !@name_to_index.nil?
    end
  end
end
