# frozen_string_literal: true

require 'time'
require 'date'

module Zone
  class Timestamp
    attr_reader :time, :zone

    def self.parse(input)
      time = case input
      in Time
        input
      in DateTime
        input.to_time
      in Date
        input.to_time
      in /^[0-9\.]+$/
        parse_unix(input)
      in /^(?<amount>[0-9\.]+) (?<unit>second|minute|hour|day|week|month|year|decade)s? (?<direction>ago|from now)$/
        parse_relative($~)
      else
        DateTime.parse(input).to_time
      end

      new(time)
    rescue StandardError
      raise ArgumentError, "Could not parse time '#{input}'"
    end

    def initialize(time, zone: nil)
      @time = time
      @zone = zone
    end

    def in_zone(zone_name)
      tz = Zone.find(zone_name)

      raise ArgumentError, "Could not find timezone '#{zone_name}'" if tz.nil?

      converted = tz.to_local(@time)

      self.class.new(
        converted,
        zone: zone_name
      )
    end

    def in_utc
      self.class.new(
        @time.utc,
        zone: 'UTC'
      )
    end

    def in_local
      self.class.new(
        @time.localtime,
        zone: 'local'
      )
    end

    def to_iso8601
      @time.utc_offset.zero? ? @time.strftime('%Y-%m-%dT%H:%M:%SZ') : @time.iso8601
    end

    def to_unix
      @time.to_i
    end

    def to_pretty(style = 1)
      case style
      when 1
        @time.strftime('%b %d, %Y - %l:%M %p %Z')
      when 2
        @time.strftime('%b %d, %Y - %H:%M %Z')
      when 3
        @time.strftime('%Y-%m-%d %H:%M %Z')
      else
        raise ArgumentError, "Invalid pretty style '#{style}' (must be 1, 2, or 3)"
      end
    end

    def strftime(format)
      @time.strftime(format)
    end

    private

    def self.parse_unix(str)
      precision = str.length - 10
      time_float = str.to_f / 10**precision
      Time.at(time_float)
    end

    def self.parse_relative(match_data)
      match_data => { amount:, unit:, direction: }

      seconds = case unit
      in 'second'
        amount.to_i
      in 'minute'
        amount.to_i * 60
      in 'hour'
        amount.to_i * 3600
      in 'day'
        amount.to_i * 86400
      in 'week'
        amount.to_i * 604800
      in 'month'
        amount.to_i * 2592000
      in 'year'
        amount.to_i * 31536000
      in 'decade'
        amount.to_i * 315360000
      end

      case direction
      in 'ago'
        Time.now - seconds
      in 'from now'
        Time.now + seconds
      end
    end
  end
end
