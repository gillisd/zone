require "../integration_helper"

# Integration tests defining 10/10 expected behavior for zone CLI
# These tests capture the correct behavior from the original implementation
describe "10/10 Behavior" do

  # ====================
  # CORE BEHAVIOR: Full Line Preservation
  # ====================

  it "field processing preserves full line with spaces" do
    output, status = run_zone_with_input(
      "user1 2025-01-15T10:30:00Z active",
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    output.strip.should match(/^user1\s+1736937000\s+active$/)
  end

  it "field processing preserves full line with comma" do
    output, status = run_zone_with_input(
      "Thomas,1901-01-01+19:07Z",
      "-z", "Tokyo", "--field", "2", "--delimiter", ",", "--iso8601"
    )

    status.should eq(0)
    # Should preserve "Thomas" and use comma as output delimiter (same as input)
    # Note: Crystal uses historical timezone offsets, so Tokyo in 1901 is +09:18, not +09:00
    output.strip.should match(/^Thomas,1900-12-31T14:11:59\+09:18$/)
  end

  it "field processing with comma and spaces" do
    output, status = run_zone_with_input(
      "name, 2025-01-15T10:30:00Z, status",
      "--field", "2", "--delimiter", ",", "--pretty"
    )

    status.should eq(0)
    # Should preserve other fields and detect comma-with-spaces delimiter
    output.strip.should match(/name.*Jan 15.*status/m)
  end

  it "field processing with tab delimiter" do
    input = "col1\t2025-01-15T10:30:00Z\tcol3"
    output, status = run_zone_with_input(
      input,
      "--field", "2", "--delimiter", "\t", "--unix"
    )

    status.should eq(0)
    output.strip.should match(/^col1\t1736937000\tcol3$/)
  end

  it "multiple lines preserve all fields" do
    input = "user1 1736937000 active\nuser2 1736940600 inactive"
    output, status = run_zone_with_input(
      input,
      "--field", "2", "--delimiter", "/\\s+/", "--pretty"
    )

    status.should eq(0)
    lines = output.strip.split("\n")
    lines.size.should eq(2)
    lines[0].should match(/user1.*Jan.*active/)
    lines[1].should match(/user2.*Jan.*inactive/)
  end

  it "headers preserves header line" do
    input = "user,timestamp,status\nalice,2025-01-15T10:30:00Z,active"
    output, status = run_zone_with_input(
      input,
      "--headers", "--field", "timestamp", "--delimiter", ",", "--unix"
    )

    status.should eq(0)
    lines = output.strip.split("\n")
    lines.size.should eq(2)
    # Header line should be preserved
    lines[0].should match(/user.*timestamp.*status/)
    # Data line should have transformed timestamp with comma delimiter
    lines[1].should match(/alice,1736937000,active/)
  end

  # ====================
  # EDGE CASE: Single Field
  # ====================

  it "field 1 with single field outputs just value" do
    output, status = run_zone_with_input(
      "2025-01-15T10:30:00Z",
      "--field", "1", "--delimiter", ",", "--unix"
    )

    status.should eq(0)
    output.strip.should eq("1736937000")
  end

  it "field 1 with multiple fields preserves line" do
    output, status = run_zone_with_input(
      "2025-01-15T10:30:00Z active",
      "--field", "1", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    # Should preserve second field
    output.strip.should match(/1736937000\s+active/)
  end

  # ====================
  # DELIMITER BEHAVIOR
  # ====================

  it "space delimiter preserved in output" do
    output, status = run_zone_with_input(
      "a 2025-01-15T10:30:00Z c",
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    # Spaces should be preserved (or become tabs)
    output.strip.should match(/^a[\s\t]+1736937000[\s\t]+c$/)
  end

  it "comma delimiter preserved in output" do
    output, status = run_zone_with_input(
      "a,2025-01-15T10:30:00Z,c",
      "--field", "2", "--delimiter", ",", "--unix"
    )

    status.should eq(0)
    # Comma delimiter should be preserved (same as input)
    output.strip.should eq("a,1736937000,c")
  end

  it "explicit delimiter preserved" do
    output, status = run_zone_with_input(
      "a|2025-01-15T10:30:00Z|c",
      "--field", "2", "--delimiter", "|", "--unix"
    )

    status.should eq(0)
    # Explicit delimiter should be preserved
    output.strip.should eq("a|1736937000|c")
  end

  # ====================
  # REAL WORLD USE CASES
  # ====================

  it "csv processing workflow" do
    csv = "name,login_time,status\nalice,1736937000,active\nbob,1736940600,inactive"
    output, status = run_zone_with_input(
      csv,
      "--headers", "--field", "login_time", "--delimiter", ",", "--zone", "Tokyo", "--pretty"
    )

    status.should eq(0)
    lines = output.strip.split("\n")
    lines.size.should eq(3)

    # Header preserved
    lines[0].should match(/name.*login_time.*status/)

    # Data lines with Tokyo time, preserving other fields
    lines[1].should match(/alice.*Jan 15.*JST.*active/)
    lines[2].should match(/bob.*Jan 15.*JST.*inactive/)
  end

  it "log processing workflow" do
    log = "[INFO] 1736937000 User logged in\n[ERROR] 1736940600 Connection failed"
    output, status = run_zone_with_input(
      log,
      "--field", "2", "--delimiter", "/\\s+/", "--pretty"
    )

    status.should eq(0)
    lines = output.strip.split("\n")

    # Should preserve log level and message (note: message is split by whitespace delimiter)
    lines[0].should match(/\[INFO\].*Jan.*User.*logged.*in/)
    lines[1].should match(/\[ERROR\].*Jan.*Connection.*failed/)
  end

  it "tsv processing with auto detection" do
    tsv = "col1\t1736937000\tcol3\ncol1\t1736940600\tcol3"
    output, status = run_zone_with_input(
      tsv,
      "--field", "2", "--delimiter", "\t", "--iso8601"
    )

    status.should eq(0)
    lines = output.strip.split("\n")

    # Tab delimiter should be detected and preserved
    lines[0].should match(/^col1\t2025-01-15T10:30:00Z\tcol3$/)
    lines[1].should match(/^col1\t2025-01-15T11:30:00Z\tcol3$/)
  end

  # ====================
  # FIELD INDEXING
  # ====================

  it "field 3 with spaces" do
    output, status = run_zone_with_input(
      "a b 1736937000 d e",
      "--field", "3", "--delimiter", "/\\s+/", "--pretty"
    )

    status.should eq(0)
    # Should preserve fields 1,2,4,5 and transform field 3
    output.strip.should match(/a.*b.*Jan.*d.*e/)
  end

  it "named field with headers" do
    output, status = run_zone_with_input(
      "user,timestamp,status\nalice,1736937000,active",
      "--headers", "--field", "timestamp", "--delimiter", ",", "--pretty"
    )

    status.should eq(0)
    lines = output.strip.split("\n")

    # Named field should work like numeric field
    lines[1].should match(/alice.*Jan.*active/)
  end

  # ====================
  # ERROR HANDLING
  # ====================

  it "invalid timestamp skips line with warning" do
    input = "user1 not-a-time active\nuser2 1736937000 active"
    output, status = run_zone_with_input(
      input,
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)

    # Should skip bad line with warning but continue
    output.should match(/Could not parse/)
    output.should match(/user2\t1736937000\tactive/)
  end

  it "out of bounds field handles gracefully" do
    output, status = run_zone_with_input(
      "a b c",
      "--field", "10", "--delimiter", "/\\s+/", "--unix"
    )

    # Should either skip or handle gracefully
    # (original behavior may vary, capture actual behavior)
    status.should eq(0)
  end

  # ====================
  # FORMAT COMBINATIONS
  # ====================

  it "unix to pretty with field preservation" do
    output, status = run_zone_with_input(
      "event1 1736937000 completed",
      "--field", "2", "--delimiter", "/\\s+/", "--pretty", "--zone", "UTC"
    )

    status.should eq(0)
    output.strip.should match(/event1.*Jan 15, 2025.*completed/)
  end

  it "iso8601 to unix with field preservation" do
    output, status = run_zone_with_input(
      "evt 2025-01-15T10:30:00Z done",
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    output.strip.should eq("evt\t1736937000\tdone")
  end

  # ====================
  # WHITESPACE HANDLING
  # ====================

  it "multiple spaces collapsed to one" do
    output, status = run_zone_with_input(
      "a    2025-01-15T10:30:00Z    c",
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    # Multiple spaces should be handled (split on /\s+/)
    output.strip.should match(/^a\s+1736937000\s+c$/)
  end

  it "leading trailing whitespace in fields" do
    output, status = run_zone_with_input(
      "  a  ,  2025-01-15T10:30:00Z  ,  c  ",
      "--field", "2", "--delimiter", ",", "--unix"
    )

    status.should eq(0)
    # Fields should be stripped before processing
    output.should match(/1736937000/)
  end
end
