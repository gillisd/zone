require "./timestamp"

module Zone
  module Transform
    extend self

    # Build a transformation lambda.
    #
    # @param [String, Symbol] zone
    #   Zone name to convert to
    #
    # @param [Symbol, Hash] format
    #   Format specification (:to_iso8601, :to_unix, {pretty: 1}, {strftime: "..."})
    #
    # @return [Proc]
    #   Lambda that transforms a timestamp string
    def build(zone : String, format : FormatType)
      ->(value : String) do
        begin
          timestamp = Timestamp.parse(value)
          converted = convert_zone(timestamp, zone)
          format_timestamp(converted, format)
        rescue ArgumentError
          nil
        end
      end
    end

    # Convert timestamp to specified zone.
    #
    # @param [Timestamp] timestamp
    # @param [String, Symbol] zone_name
    #
    # @return [Timestamp]
    def convert_zone(timestamp : Timestamp, zone_name : String)
      case zone_name
      when "utc", "UTC"
        timestamp.in_utc
      when "local"
        timestamp.in_local
      else
        timestamp.in_zone(zone_name)
      end
    end

    # Format timestamp according to format specification.
    #
    # @param [Timestamp] timestamp
    # @param [Symbol, Hash] format_spec
    #
    # @return [String, Integer]
    def format_timestamp(timestamp : Timestamp, format_spec : FormatType)
      case format_spec
      when Symbol
        case format_spec
        when :to_iso8601
          timestamp.to_iso8601
        when :to_unix
          timestamp.to_unix
        else
          timestamp.to_s
        end
      when NamedTuple(pretty: Int32)
        timestamp.to_pretty(format_spec[:pretty])
      when NamedTuple(strftime: String)
        timestamp.strftime(format_spec[:strftime])
      else
        timestamp.to_s
      end
    end
  end
end
