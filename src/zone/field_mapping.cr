module Zone
  class FieldMapping
    def self.from_fields(fields : Array(String)) : FieldMapping
      name_to_index = fields.each_with_index.to_h
      new(name_to_index: name_to_index)
    end

    def self.numeric : FieldMapping
      new(name_to_index: nil)
    end

    def initialize(@name_to_index : Hash(String, Int32)?)
    end

    def resolve(key : String | Int32) : Int32
      case key
      when String
        if key.matches?(/^\d+$/)
          # Numeric string - convert to integer and resolve
          key.to_i - 1
        else
          if (mapping = @name_to_index)
            mapping.fetch(key) do
              raise KeyError.new("Field '#{key}' not found in mapping")
            end
          else
            raise KeyError.new("Cannot access field by name without headers. Use --headers or numeric field index.")
          end
        end
      when Int32
        # Convert 1-based user input to 0-based array index
        key - 1
      else
        raise ArgumentError.new("Key must be String or Int32, got #{key.class}")
      end
    end

    def [](key : String | Int32) : Int32
      resolve(key)
    end

    def names : Array(String)
      @name_to_index.try(&.keys) || [] of String
    end

    def has_names? : Bool
      !@name_to_index.nil?
    end
  end
end
