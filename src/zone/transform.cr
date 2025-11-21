require "./timestamp"

module Zone
  module Transform
    extend self

    #
    # Build a transformation lambda.
    #
    def build(zone : String, format : Symbol | Hash(Symbol, String | Int32)) : Proc(String, String?)
      ->(value : String) : String? do
        timestamp = Timestamp.parse(value)
        converted = convert_zone(timestamp, zone)
        format_timestamp(converted, format).to_s
      rescue
        nil
      end
    end

    #
    # Convert timestamp to specified zone.
    #
    def convert_zone(timestamp : Timestamp, zone_name : String) : Timestamp
      case zone_name
      when "utc", "UTC"
        timestamp.in_utc
      when "local"
        timestamp.in_local
      else
        timestamp.in_zone(zone_name)
      end
    end

    #
    # Format timestamp according to format specification.
    #
    def format_timestamp(timestamp : Timestamp, format_spec : Symbol | Hash(Symbol, String | Int32)) : String | Int64
      case format_spec
      when :to_iso8601
        timestamp.to_iso8601
      when :to_unix
        timestamp.to_unix
      when Hash
        if format_spec.has_key?(:pretty)
          style = format_spec[:pretty].as(Int32)
          timestamp.to_pretty(style)
        elsif format_spec.has_key?(:strftime)
          fmt = format_spec[:strftime].as(String)
          timestamp.strftime(fmt)
        else
          timestamp.to_iso8601
        end
      else
        timestamp.to_iso8601
      end
    end
  end
end
