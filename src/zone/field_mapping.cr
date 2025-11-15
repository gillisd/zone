module Zone
  class FieldMapping
    getter names : Array(String)
    @name_to_index : Hash(String, Int32)

    def self.from_fields(fields : Array(String)) : FieldMapping
      name_to_index = {} of String => Int32
      fields.each_with_index do |name, index|
        name_to_index[name] = index
      end
      new(name_to_index: name_to_index)
    end

    def self.numeric : FieldMapping
      new(name_to_index: {} of String => Int32)
    end

    def initialize(name_to_index : Hash(String, Int32))
      @name_to_index = name_to_index
      @names = name_to_index.keys
    end

    def resolve(key : String | Int32) : Int32
      case key
      when String
        # Try as field name first
        if @name_to_index.has_key?(key)
          return @name_to_index[key]
        end
        # Try as numeric string
        if key.matches?(/^\d+$/)
          return key.to_i - 1
        end
        raise KeyError.new("Field '#{key}' not found in mapping")
      when Int32
        key - 1  # Convert 1-indexed to 0-indexed
      else
        raise ArgumentError.new("Invalid key type: #{key.class}")
      end
    end

    def [](key : String | Int32) : Int32
      resolve(key)
    end

    def has_names? : Bool
      !@name_to_index.empty?
    end
  end
end
