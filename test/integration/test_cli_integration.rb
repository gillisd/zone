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
    assert_match(/2025-01-15T10:30:00/, output)
  end

  def test_convert_timestamp_to_specific_zone
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "Tokyo")

    assert_equal 0, status
    assert_match(/2025-01-15T19:30:00/, output)
  end

  def test_convert_unix_timestamp
    output, status = run_zone("1736937000", "--zone", "UTC")

    assert_equal 0, status
    assert_match(/2025-01-15/, output)
  end

  def test_pretty_format_output
    output, status = run_zone("2025-01-15T10:30:00Z", "--pretty")

    assert_equal 0, status
    assert_match(/Jan/, output)
    assert_match(/\d{1,2}:\d{2} [AP]M/, output)
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
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    assert_equal 0, status
    assert_equal "1736937000\n", output
  end

  def test_extract_field_with_tab_delimiter
    output, status = run_zone_with_input(
      "foo\t1736937000\tbar",
      "--field", "2", "--delimiter", "\t", "--unix"
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
      "--field", "timestamp", "--delimiter", ",", "--headers", "--unix"
    )

    assert_equal 0, status
    refute_match(/timestamp/, output)
    assert_match(/1736937000/, output)
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
      assert_match(/Jan/, line)
    end
  end

  def test_fuzzy_timezone_search
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "tokyo")

    assert_equal 0, status
    assert_match(/2025-01-15T19:30:00/, output)
  end

  def test_local_timezone_conversion
    output, status = run_zone("2025-01-15T10:30:00Z", "--local")

    assert_equal 0, status
    assert_match(/2025-01-15/, output)
  end

  def test_verbose_logging
    output, status = run_zone("2025-01-15T10:30:00Z", "--verbose", "--utc")

    assert_equal 0, status
    assert_match(/DEBUG/, output)
  end

  def test_invalid_timestamp_returns_error
    output, status = run_zone("not_a_valid_timestamp")

    refute_equal 0, status
    assert_match(/Could not parse time/, output)
  end

  def test_invalid_timezone_returns_error
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "NotARealTimezone12345")

    refute_equal 0, status
    assert_match(/Could not find timezone/, output)
  end

  def test_combined_field_and_zone_conversion
    output, status = run_zone_with_input(
      "data,1736937000,more",
      "--field", "2", "--zone", "Tokyo", "--delimiter", ","
    )

    assert_equal 0, status
    assert_match(/2025-01-15T19:30:00/, output)
    assert_match(/\+09:00/, output)
  end

  def test_date_command_format_with_spaces
    output, status = run_zone("Wed Nov 12 19:13:17 UTC 2025", "--utc")

    assert_equal 0, status
    assert_match(/2025-11-12T19:13:17/, output)
  end

  def test_piped_date_format
    output, status = run_zone_with_input(
      "Wed Nov 12 19:13:17 UTC 2025",
      "--utc"
    )

    assert_equal 0, status
    assert_match(/2025-11-12T19:13:17/, output)
  end

  def test_date_format_with_timezone_abbreviation
    output, status = run_zone("Wed Nov 12 14:11:40 EST 2025", "--utc")

    assert_equal 0, status
    assert_match(/2025-11-12/, output)
  end

  def test_multiline_date_formats
    input = "Wed Nov 12 10:30:00 UTC 2025\nThu Nov 13 11:45:00 UTC 2025"
    output, status = run_zone_with_input(input, "--utc")

    assert_equal 0, status
    lines = output.split("\n")
    assert_equal 2, lines.count
    assert_match(/2025-11-12T10:30:00/, lines[0])
    assert_match(/2025-11-13T11:45:00/, lines[1])
  end

  def test_field_processing_not_triggered_by_default
    # Ensure spaces in timestamp don't cause field splitting
    output, status = run_zone("2025-01-15 10:30:00", "--utc")

    assert_equal 0, status
    assert_match(/2025-01-15T10:30:00/, output)
  end

  def test_explicit_field_1_still_works
    output, status = run_zone_with_input(
      "1736937000 extra data",
      "--field", "1", "--delimiter", "/\\s+/", "--unix"
    )

    assert_equal 0, status
    assert_equal "1736937000\n", output
  end

  def test_no_arguments_uses_current_time
    # When STDIN is a tty (interactive), zone with no args uses Time.now
    # In automated tests, STDIN is not a tty, so we skip this test
    skip "Cannot test TTY behavior in automated tests"
  end

  def test_multiple_timestamp_arguments
    output, status = run_zone(
      "2025-01-15T10:30:00Z",
      "2025-01-16T11:00:00Z",
      "--utc"
    )

    assert_equal 0, status
    lines = output.split("\n")
    assert_equal 2, lines.count
    assert_match(/2025-01-15T10:30:00/, lines[0])
    assert_match(/2025-01-16T11:00:00/, lines[1])
  end

  def test_empty_line_input_skipped_with_warning
    output, status = run_zone_with_input("", "--utc")

    assert_equal 0, status
    assert_match(/Warning.*Could not parse/, output)
  end

  def test_mixed_valid_and_invalid_timestamps
    input = "2025-01-15T10:30:00Z\ninvalid\n2025-01-16T10:30:00Z"
    output, status = run_zone_with_input(input, "--utc")

    assert_equal 0, status
    assert_match(/2025-01-15T10:30:00/, output)
    assert_match(/2025-01-16T10:30:00/, output)
    assert_match(/Warning/, output)
  end

  def test_out_of_bounds_field_index_warns
    output, status = run_zone_with_input(
      "a,b,c",
      "--field", "5", "--delimiter", ","
    )

    assert_equal 0, status
    assert_match(/Warning/, output)
  end

  def test_nonexistent_field_name_returns_error
    output, status = run_zone_with_input(
      "a,b,c",
      "--field", "nonexistent", "--delimiter", ","
    )

    refute_equal 0, status
    assert_match(/Error/, output)
  end

  def test_headers_only_input_produces_no_output
    output, status = run_zone_with_input(
      "name,timestamp,value",
      "--field", "timestamp", "--delimiter", ",", "--headers"
    )

    assert_equal 0, status
    assert_empty output.strip
  end
end
