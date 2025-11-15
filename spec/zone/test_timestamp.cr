# frozen_string_literal: true

require "test_helper"

class TestTimestamp < Minitest::Test
  def test_parse_time_object
    time = Time.now
    timestamp = Zone::Timestamp.parse(time)

    assert_instance_of Zone::Timestamp, timestamp
    assert_equal time, timestamp.time
  end

  def test_parse_datetime_object
    datetime = DateTime.now
    timestamp = Zone::Timestamp.parse(datetime)

    assert_instance_of Zone::Timestamp, timestamp
    assert_instance_of Time, timestamp.time
  end

  def test_parse_date_object
    date = Date.today
    timestamp = Zone::Timestamp.parse(date)

    assert_instance_of Zone::Timestamp, timestamp
    assert_instance_of Time, timestamp.time
  end

  def test_parse_unix_timestamp_seconds
    # Unix epoch for 2025-01-15 10:30:00 UTC
    timestamp = Zone::Timestamp.parse("1736937000")

    assert_equal 1736937000, timestamp.time.to_i
  end

  def test_parse_unix_timestamp_milliseconds
    # 13 digits - milliseconds precision
    timestamp = Zone::Timestamp.parse("1736937000000")

    assert_equal 1736937000, timestamp.time.to_i
  end

  def test_parse_iso8601_string
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")

    assert_equal 2025, timestamp.time.year
    assert_equal 1, timestamp.time.month
    assert_equal 15, timestamp.time.day
    assert_equal 10, timestamp.time.hour
    assert_equal 30, timestamp.time.min
  end

  def test_parse_relative_time_ago
    timestamp = Zone::Timestamp.parse("5 minutes ago")
    diff = Time.now - timestamp.time

    assert_in_delta 300, diff, 2
  end

  def test_parse_relative_time_from_now
    timestamp = Zone::Timestamp.parse("1 hour from now")
    diff = timestamp.time - Time.now

    assert_in_delta 3600, diff, 2
  end

  def test_parse_invalid_input_raises_error
    error = assert_raises(ArgumentError) do
      Zone::Timestamp.parse("not a valid timestamp")
    end

    assert_match(/Could not parse time/, error.message)
  end

  def test_in_zone_returns_new_timestamp
    original = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    tokyo = original.in_zone("Tokyo")

    assert_instance_of Zone::Timestamp, tokyo
    refute_same original, tokyo
    assert_equal "Tokyo", tokyo.zone
  end

  def test_in_utc_returns_new_timestamp
    local = Zone::Timestamp.parse(Time.now.to_s)
    utc = local.in_utc

    assert_instance_of Zone::Timestamp, utc
    assert_equal "UTC", utc.zone
  end

  def test_in_local_returns_new_timestamp
    utc = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    local = utc.in_local

    assert_instance_of Zone::Timestamp, local
    assert_equal "local", local.zone
  end

  def test_to_iso8601_format
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    formatted = timestamp.to_iso8601

    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, formatted)
  end

  def test_to_unix_returns_integer
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    unix = timestamp.to_unix

    assert_instance_of Integer, unix
    assert_equal 1736937000, unix
  end

  def test_to_pretty_format
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    pretty = timestamp.to_pretty

    assert_match(/Jan \d+/, pretty)
    assert_match(/\d{1,2}:\d{2} [AP]M/, pretty)
  end

  def test_strftime_custom_format
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    formatted = timestamp.strftime("%Y-%m-%d")

    assert_equal "2025-01-15", formatted
  end

  def test_chainable_operations
    result = Zone::Timestamp
      .parse("2025-01-15T10:30:00Z")
      .in_zone("Tokyo")
      .to_iso8601

    assert_instance_of String, result
    assert_match(/\+09:00/, result)
  end

  def test_responds_to_all_public_methods
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")

    assert_respond_to timestamp, :in_zone
    assert_respond_to timestamp, :in_utc
    assert_respond_to timestamp, :in_local
    assert_respond_to timestamp, :to_iso8601
    assert_respond_to timestamp, :to_unix
    assert_respond_to timestamp, :to_pretty
    assert_respond_to timestamp, :strftime
  end
end
