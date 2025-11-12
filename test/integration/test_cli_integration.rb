# frozen_string_literal: true

require "test_helper"

class TestCliIntegration < Minitest::Test
  def setup
    @zone_bin = File.expand_path("../../exe/zone", __dir__)
  end

  def run_zone(*args)
    escaped_args = args.map { |arg| "'#{arg}'" }.join(" ")
    output = `#{@zone_bin} #{escaped_args} 2>&1`
    [output, $?.exitstatus]
  end

  def run_zone_with_input(input, *args)
    escaped_args = args.map { |arg| "'#{arg}'" }.join(" ")
    output = `echo "#{input}" | #{@zone_bin} #{escaped_args} 2>&1`
    [output, $?.exitstatus]
  end

  def test_convert_timestamp_to_utc
    output, status = run_zone("2025-01-15T10:30:00Z", "--utc")

    assert_equal 0, status
    assert_match /2025-01-15T10:30:00/, output
  end

  def test_convert_timestamp_to_specific_zone
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "Tokyo")

    assert_equal 0, status
    assert_match /2025-01-15T19:30:00/, output
  end

  def test_convert_unix_timestamp
    output, status = run_zone("1736937000", "--zone", "UTC")

    assert_equal 0, status
    assert_match /2025-01-15/, output
  end

  def test_pretty_format_output
    output, status = run_zone("2025-01-15T10:30:00Z", "--pretty")

    assert_equal 0, status
    assert_match /Jan/, output
    assert_match /\d{1,2}:\d{2} [AP]M/, output
  end

  def test_unix_format_output
    output, status = run_zone("2025-01-15T10:30:00Z", "--unix")

    assert_equal 0, status
    assert_equal "1736937000\n", output
  end

  def test_custom_strftime_format
    output, status = run_zone("2025-01-15T10:30:00Z", "--strftime", "%Y-%m-%d")

    assert_equal 0, status
    assert_equal "2025-01-15\n", output
  end

  def test_extract_field_by_index
    output, status = run_zone_with_input(
      "test 1736937000 data",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    assert_equal "1736937000\n", output
  end

  def test_extract_field_with_tab_delimiter
    output, status = run_zone_with_input(
      "foo\t1736937000\tbar",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    assert_equal "1736937000\n", output
  end

  def test_extract_field_with_custom_delimiter
    output, status = run_zone_with_input(
      "foo|1736937000|bar",
      "--field", "2", "--delimiter", "|", "--unix"
    )

    assert_equal 0, status
    assert_equal "1736937000\n", output
  end

  def test_field_with_headers
    input = "timestamp,value,name\n1736937000,100,test"
    output, status = run_zone_with_input(
      input,
      "--field", "timestamp", "--headers", "--unix"
    )

    assert_equal 0, status
    refute_match /timestamp/, output
    assert_match /1736937000/, output
  end

  def test_multiple_lines_processing
    input = "1736937000\n1736940600\n1736944200"
    output, status = run_zone_with_input(
      input,
      "--pretty"
    )

    assert_equal 0, status
    lines = output.split("\n")
    assert_equal 3, lines.count
    lines.each do |line|
      assert_match /Jan/, line
    end
  end

  def test_fuzzy_timezone_search
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "tokyo")

    assert_equal 0, status
    assert_match /2025-01-15T19:30:00/, output
  end

  def test_local_timezone_conversion
    output, status = run_zone("2025-01-15T10:30:00Z", "--local")

    assert_equal 0, status
    assert_match /2025-01-15/, output
  end

  def test_verbose_logging
    output, status = run_zone("2025-01-15T10:30:00Z", "--verbose", "--utc")

    assert_equal 0, status
    assert_match /DEBUG/, output
  end

  def test_invalid_timestamp_returns_error
    output, status = run_zone("not_a_valid_timestamp")

    refute_equal 0, status
    assert_match /Could not parse time/, output
  end

  def test_invalid_timezone_returns_error
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "NotARealTimezone12345")

    refute_equal 0, status
    assert_match /Could not find timezone/, output
  end

  def test_combined_field_and_zone_conversion
    output, status = run_zone_with_input(
      "data,1736937000,more",
      "--field", "2", "--zone", "Tokyo", "--delimiter", ","
    )

    assert_equal 0, status
    assert_match /2025-01-15T19:30:00/, output
    assert_match /\+09:00/, output
  end
end
