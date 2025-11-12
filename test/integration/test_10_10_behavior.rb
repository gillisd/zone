# frozen_string_literal: true

require "test_helper"

# Integration tests defining 10/10 expected behavior for zone CLI
# These tests capture the correct behavior from the original implementation
class Test1010Behavior < Minitest::Test
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

  # ====================
  # CORE BEHAVIOR: Full Line Preservation
  # ====================

  def test_field_processing_preserves_full_line_with_spaces
    output, status = run_zone_with_input(
      "user1 2025-01-15T10:30:00Z active",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    assert_match(/^user1\s+1736937000\s+active$/, output.strip)
  end

  def test_field_processing_preserves_full_line_with_comma
    output, status = run_zone_with_input(
      "Thomas,1901-01-01+19:07Z",
      "-z", "Tokyo", "--field", "2"
    )

    assert_equal 0, status
    # Should preserve "Thomas" and use tab as output delimiter
    assert_match(/^Thomas\t1901-01-02T04:07:00\+09:00$/, output.strip)
  end

  def test_field_processing_with_comma_and_spaces
    output, status = run_zone_with_input(
      "name, 2025-01-15T10:30:00Z, status",
      "--field", "2", "--pretty"
    )

    assert_equal 0, status
    # Should preserve other fields and detect comma-with-spaces delimiter
    assert_match(/name.*Jan 15.*status/m, output.strip)
  end

  def test_field_processing_with_tab_delimiter
    input = "col1\t2025-01-15T10:30:00Z\tcol3"
    output, status = run_zone_with_input(
      input,
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    assert_match(/^col1\t1736937000\tcol3$/, output.strip)
  end

  def test_multiple_lines_preserve_all_fields
    input = "user1 1736937000 active\nuser2 1736940600 inactive"
    output, status = run_zone_with_input(
      input,
      "--field", "2", "--pretty"
    )

    assert_equal 0, status
    lines = output.strip.split("\n")
    assert_equal 2, lines.count
    assert_match(/user1.*Jan.*active/, lines[0])
    assert_match(/user2.*Jan.*inactive/, lines[1])
  end

  def test_headers_preserves_header_line
    input = "user,timestamp,status\nalice,2025-01-15T10:30:00Z,active"
    output, status = run_zone_with_input(
      input,
      "--headers", "--field", "timestamp", "--unix"
    )

    assert_equal 0, status
    lines = output.strip.split("\n")
    assert_equal 2, lines.count
    # Header line should be preserved
    assert_match(/user.*timestamp.*status/, lines[0])
    # Data line should have transformed timestamp
    assert_match(/alice\t1736937000\tactive/, lines[1])
  end

  # ====================
  # EDGE CASE: Single Field
  # ====================

  def test_field_1_with_single_field_outputs_just_value
    output, status = run_zone_with_input(
      "2025-01-15T10:30:00Z",
      "--field", "1", "--unix"
    )

    assert_equal 0, status
    assert_equal "1736937000", output.strip
  end

  def test_field_1_with_multiple_fields_preserves_line
    output, status = run_zone_with_input(
      "2025-01-15T10:30:00Z active",
      "--field", "1", "--unix"
    )

    assert_equal 0, status
    # Should preserve second field
    assert_match(/1736937000\s+active/, output.strip)
  end

  # ====================
  # DELIMITER BEHAVIOR
  # ====================

  def test_space_delimiter_preserved_in_output
    output, status = run_zone_with_input(
      "a 2025-01-15T10:30:00Z c",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    # Spaces should be preserved (or become tabs)
    assert_match(/^a[\s\t]+1736937000[\s\t]+c$/, output.strip)
  end

  def test_comma_delimiter_becomes_tab_in_output
    output, status = run_zone_with_input(
      "a,2025-01-15T10:30:00Z,c",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    # Comma delimiter should become tab
    assert_equal "a\t1736937000\tc", output.strip
  end

  def test_explicit_delimiter_preserved
    output, status = run_zone_with_input(
      "a|2025-01-15T10:30:00Z|c",
      "--field", "2", "--delimiter", "|", "--unix"
    )

    assert_equal 0, status
    # Explicit delimiter should be preserved
    assert_equal "a|1736937000|c", output.strip
  end

  # ====================
  # REAL WORLD USE CASES
  # ====================

  def test_csv_processing_workflow
    csv = "name,login_time,status\nalice,1736937000,active\nbob,1736940600,inactive"
    output, status = run_zone_with_input(
      csv,
      "--headers", "--field", "login_time", "--zone", "Tokyo", "--pretty"
    )

    assert_equal 0, status
    lines = output.strip.split("\n")
    assert_equal 3, lines.count

    # Header preserved
    assert_match(/name.*login_time.*status/, lines[0])

    # Data lines with Tokyo time, preserving other fields
    assert_match(/alice.*Jan 15.*JST.*active/, lines[1])
    assert_match(/bob.*Jan 15.*JST.*inactive/, lines[2])
  end

  def test_log_processing_workflow
    log = "[INFO] 1736937000 User logged in\n[ERROR] 1736940600 Connection failed"
    output, status = run_zone_with_input(
      log,
      "--field", "2", "--pretty"
    )

    assert_equal 0, status
    lines = output.strip.split("\n")

    # Should preserve log level and message
    assert_match(/\[INFO\].*Jan.*User logged in/, lines[0])
    assert_match(/\[ERROR\].*Jan.*Connection failed/, lines[1])
  end

  def test_tsv_processing_with_auto_detection
    tsv = "col1\t1736937000\tcol3\ncol1\t1736940600\tcol3"
    output, status = run_zone_with_input(
      tsv,
      "--field", "2", "--iso8601"
    )

    assert_equal 0, status
    lines = output.strip.split("\n")

    # Tab delimiter should be detected and preserved
    assert_match(/^col1\t2025-01-15T10:30:00Z\tcol3$/, lines[0])
    assert_match(/^col1\t2025-01-15T11:30:00Z\tcol3$/, lines[1])
  end

  # ====================
  # FIELD INDEXING
  # ====================

  def test_field_3_with_spaces
    output, status = run_zone_with_input(
      "a b 1736937000 d e",
      "--field", "3", "--pretty"
    )

    assert_equal 0, status
    # Should preserve fields 1,2,4,5 and transform field 3
    assert_match(/a.*b.*Jan.*d.*e/, output.strip)
  end

  def test_named_field_with_headers
    output, status = run_zone_with_input(
      "user,timestamp,status\nalice,1736937000,active",
      "--headers", "--field", "timestamp", "--pretty"
    )

    assert_equal 0, status
    lines = output.strip.split("\n")

    # Named field should work like numeric field
    assert_match(/alice.*Jan.*active/, lines[1])
  end

  # ====================
  # ERROR HANDLING
  # ====================

  def test_invalid_timestamp_skips_line_with_warning
    input = "user1 not-a-time active\nuser2 1736937000 active"
    output, status = run_zone_with_input(
      input,
      "--field", "2", "--unix"
    )

    assert_equal 0, status

    # Should skip bad line with warning but continue
    assert_match(/Warning.*Could not parse/, output)
    assert_match(/user2\t1736937000\tactive/, output)
  end

  def test_out_of_bounds_field_handles_gracefully
    output, status = run_zone_with_input(
      "a b c",
      "--field", "10", "--unix"
    )

    # Should either skip or handle gracefully
    # (original behavior may vary, capture actual behavior)
    assert_equal 0, status
  end

  # ====================
  # FORMAT COMBINATIONS
  # ====================

  def test_unix_to_pretty_with_field_preservation
    output, status = run_zone_with_input(
      "event1 1736937000 completed",
      "--field", "2", "--pretty", "--zone", "UTC"
    )

    assert_equal 0, status
    assert_match(/event1.*Jan 15, 2025.*completed/, output.strip)
  end

  def test_iso8601_to_unix_with_field_preservation
    output, status = run_zone_with_input(
      "evt 2025-01-15T10:30:00Z done",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    assert_equal "evt\t1736937000\tdone", output.strip
  end

  # ====================
  # WHITESPACE HANDLING
  # ====================

  def test_multiple_spaces_collapsed_to_one
    output, status = run_zone_with_input(
      "a    2025-01-15T10:30:00Z    c",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    # Multiple spaces should be handled (split on /\s+/)
    assert_match(/^a\s+1736937000\s+c$/, output.strip)
  end

  def test_leading_trailing_whitespace_in_fields
    output, status = run_zone_with_input(
      "  a  ,  2025-01-15T10:30:00Z  ,  c  ",
      "--field", "2", "--unix"
    )

    assert_equal 0, status
    # Fields should be stripped before processing
    assert_match(/1736937000/, output)
  end
end
