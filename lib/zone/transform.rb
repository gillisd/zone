# frozen_string_literal: true

require_relative 'timestamp'
require_relative '../zone'

module Zone
  module Transform
    module_function

    #
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
    #
    def build(zone:, format:)
      ->(value) do
        timestamp = Timestamp.parse(value)
        converted = convert_zone(timestamp, zone)
        format_timestamp(converted, format)
      rescue ArgumentError
        nil
      end
    end

    #
    # Convert timestamp to specified zone.
    #
    # @param [Timestamp] timestamp
    # @param [String, Symbol] zone_name
    #
    # @return [Timestamp]
    #
    def convert_zone(timestamp, zone_name)
      case zone_name
      in 'utc' | 'UTC'
        timestamp.in_utc
      in 'local'
        timestamp.in_local
      else
        timestamp.in_zone(zone_name)
      end
    end

    #
    # Format timestamp according to format specification.
    #
    # @param [Timestamp] timestamp
    # @param [Symbol, Hash] format_spec
    #
    # @return [String, Integer]
    #
    def format_timestamp(timestamp, format_spec)
      case format_spec
      in :to_iso8601 | :to_unix
        timestamp.send(format_spec)
      in { pretty: Integer => style }
        timestamp.to_pretty(style)
      in { strftime: String => fmt }
        timestamp.strftime(fmt)
      end
    end
  end
end
