require "../integration_helper"

describe "CLI Integration" do

  it "converts timestamp to UTC" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--utc", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T10:30:00/)
  end

  it "converts timestamp to specific zone" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "Tokyo", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T19:30:00/)
  end

  it "converts unix timestamp" do
    output, status = run_zone("1736937000", "--zone", "UTC")

    status.should eq(0)
    output.should match(/Jan 15, 2025/)
  end

  it "outputs in pretty format" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--pretty")

    status.should eq(0)
    output.should match(/Jan/)
    output.should match(/\d{1,2}:\d{2} [AP]M/)
  end

  it "outputs as unix timestamp" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--unix")

    status.should eq(0)
    output.strip.should eq("1736937000")
  end

  it "supports custom strftime format" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--strftime", "%Y-%m-%d")

    status.should eq(0)
    output.strip.should eq("2025-01-15")
  end

  it "extracts field by index" do
    output, status = run_zone_with_input(
      "test 1736937000 data",
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    output.should match(/test\s+1736937000\s+data/)
  end

  it "extracts field with tab delimiter" do
    output, status = run_zone_with_input(
      "foo\t1736937000\tbar",
      "--field", "2", "--delimiter", "\t", "--unix"
    )

    status.should eq(0)
    output.strip.should eq("foo\t1736937000\tbar")
  end

  it "extracts field with custom delimiter" do
    output, status = run_zone_with_input(
      "foo|1736937000|bar",
      "--field", "2", "--delimiter", "|", "--unix"
    )

    status.should eq(0)
    output.strip.should eq("foo|1736937000|bar")
  end

  it "processes fields with headers" do
    input = "timestamp,value,name\n1736937000,100,test"
    output, status = run_zone_with_input(
      input,
      "--field", "timestamp", "--delimiter", ",", "--headers", "--unix"
    )

    status.should eq(0)
    lines = output.strip.split("\n")
    lines.size.should eq(2)
    lines[0].should match(/timestamp/)  # Header line preserved
    lines[1].should match(/1736937000/)  # Data line
  end

  it "processes multiple lines" do
    input = "1736937000\n1736940600\n1736944200"
    output, status = run_zone_with_input(input, "--pretty")

    status.should eq(0)
    lines = output.strip.split("
")
    lines.size.should eq(3)
    lines.each do |line|
      line.should match(/Jan/)
    end
  end

  it "performs fuzzy timezone search" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "tokyo", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T19:30:00/)
  end

  it "converts to local timezone" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--local")

    status.should eq(0)
    output.should match(/Jan 15, 2025/)
  end

  it "enables verbose logging" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--verbose", "--utc")

    status.should eq(0)
    output.should match(/DEBUG/)
  end

  it "returns error for invalid timestamp" do
    output, status = run_zone("not_a_valid_timestamp")

    status.should_not eq(0)
    output.should match(/Could not parse time/)
  end

  it "returns error for invalid timezone" do
    output, status = run_zone("2025-01-15T10:30:00Z", "--zone", "NotARealTimezone12345")

    status.should_not eq(0)
    output.should match(/Could not find timezone/)
  end

  it "returns error for invalid pretty format" do
    output, status = run_zone("2025-01-15T10:30:00Z", "-p4")

    status.should_not eq(0)
    output.should match(/Invalid pretty format -p4/)
    output.should match(/must be 1, 2, or 3/)
  end

  it "combines field and zone conversion" do
    output, status = run_zone_with_input(
      "data,1736937000,more",
      "--field", "2", "--zone", "Tokyo", "--delimiter", ",", "--iso8601"
    )

    status.should eq(0)
    output.should match(/2025-01-15T19:30:00/)
    output.should match(/\+09:00/)
  end

  it "parses date command format with spaces" do
    output, status = run_zone("Wed Nov 12 19:13:17 UTC 2025", "--utc", "--iso8601")

    status.should eq(0)
    output.should match(/2025-11-12T19:13:17/)
  end

  it "parses piped date format" do
    output, status = run_zone_with_input(
      "Wed Nov 12 19:13:17 UTC 2025",
      "--utc", "--iso8601"
    )

    status.should eq(0)
    output.should match(/2025-11-12T19:13:17/)
  end

  it "parses date format with timezone abbreviation" do
    output, status = run_zone("Wed Nov 12 14:11:40 EST 2025", "--utc")

    status.should eq(0)
    output.should match(/Nov 12, 2025/)
  end

  it "processes multiline date formats" do
    input = "Wed Nov 12 10:30:00 UTC 2025\nThu Nov 13 11:45:00 UTC 2025"
    output, status = run_zone_with_input(input, "--utc", "--iso8601")

    lines = output.strip.split("
")
    lines = output.strip.split("\n")
    lines.size.should eq(2)
    lines[0].should match(/2025-11-12T10:30:00/)
    lines[1].should match(/2025-11-13T11:45:00/)
  end

  it "doesn't trigger field processing by default" do
    # Ensure spaces in timestamp don't cause field splitting
    output, status = run_zone("2025-01-15 10:30:00", "--utc", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T10:30:00/)
  end

  it "works with explicit field 1" do
    output, status = run_zone_with_input(
      "1736937000 extra data",
      "--field", "1", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    output.should match(/1736937000\s+extra\s+data/)
  end

  pending "uses current time with no arguments in TTY mode" do
    # When STDIN is a tty (interactive), zone with no args uses Time.now
    # In automated tests, STDIN is not a tty, so we skip this test
  end

  it "handles multiple timestamp arguments" do
    output, status = run_zone(
      "2025-01-15T10:30:00Z",
      "2025-01-16T11:00:00Z",
      "--utc", "--iso8601"
    )
    lines = output.strip.split("
")
    status.should eq(0)
    lines = output.strip.split("\n")
    lines.size.should eq(2)
    lines[0].should match(/2025-01-15T10:30:00/)
    lines[1].should match(/2025-01-16T11:00:00/)
  end

  it "passes through empty line input" do
    output, status = run_zone_with_input("\n", "--utc")

    status.should eq(0)
    # Piped empty line passes through silently, no warning
    output.should eq("\n")
  end

  it "handles mixed valid and invalid timestamps" do
    input = "2025-01-15T10:30:00Z\ninvalid\n2025-01-16T10:30:00Z"
    output, status = run_zone_with_input(input, "--utc", "--iso8601")

    status.should eq(0)
    # Timestamps are converted
    output.should match(/2025-01-15T10:30:00/)
    output.should match(/2025-01-16T10:30:00/)
    # Non-matching line passes through silently (no warning for piped input)
    output.should match(/invalid/)
    output.should_not match(/⚠/)
  end

  it "warns for out of bounds field index" do
    output, status = run_zone_with_input(
      "a,b,c",
      "--field", "5", "--delimiter", ","
    )

    status.should eq(0)
    output.should match(/⚠/)
  end

  it "returns error for nonexistent field name" do
    output, status = run_zone_with_input(
      "a,b,c",
      "--field", "nonexistent", "--delimiter", ","
    )

    status.should_not eq(0)
    output.should match(/Error/)
  end

  it "outputs header when only headers provided" do
    output, status = run_zone_with_input(
      "name,timestamp,value",
      "--field", "timestamp", "--delimiter", ",", "--headers"
    )

    status.should eq(0)
    # Header line is output even when there's no data
    output.strip.should match(/name.*timestamp.*value/)
  end

  it "preserves timezone offset in timestamp" do
    # Critical regression test: ensure timezone offset is not stripped during pattern matching
    # Bug was: "2025-01-15 16:30:00 -0500" would match as "2025-01-15 16:30:00" (no offset)
    # and be parsed as UTC, resulting in 5-hour error when converting to EST
    output, status = run_zone("2025-01-15 16:30:00 -0500", "--zone", "America/New_York")

    status.should eq(0)
    # Should show 4:30 PM (16:30), not 11:30 AM (5 hours earlier)
    output.should match(/4:30 PM/)
    output.should match(/EST/)
  end

  it "preserves timezone offset when converting to ISO8601" do
    # Verify timezone offset is preserved in parsing and conversion
    output, status = run_zone("2025-01-15 16:30:00 -0500", "--iso8601", "--zone", "UTC")

    status.should eq(0)
    # -0500 is EST, which is UTC+5, so 16:30 EST = 21:30 UTC
    output.should match(/2025-01-15T21:30:00/)
  end

  # Quoted timestamp tests
  it "handles double-quoted ISO8601 timestamp" do
    output, status = run_zone_with_input(
      "\"2025-01-15T10:30:00+09:00\"",
      "--zone", "UTC", "--iso8601"
    )

    status.should eq(0)
    # Should convert to UTC (subtract 9 hours) and preserve quotes
    output.strip.should eq("\"2025-01-15T01:30:00Z\"")
  end

  it "handles single-quoted ISO8601 timestamp" do
    output, status = run_zone_with_input(
      "'2025-01-15T10:30:00+09:00'",
      "--zone", "UTC", "--iso8601"
    )

    status.should eq(0)
    # Should convert to UTC (subtract 9 hours) and preserve quotes
    output.strip.should eq("'2025-01-15T01:30:00Z'")
  end

  it "handles quoted unix timestamp" do
    output, status = run_zone_with_input(
      "\"1736937000\"",
      "--zone", "America/New_York", "--pretty"
    )

    status.should eq(0)
    # Should convert unix to pretty format and preserve quotes
    output.should match(/"Jan 15, 2025/)
    output.should match(/EST"/)
  end

  it "handles quoted timestamp in CSV field" do
    output, status = run_zone_with_input(
      "name,\"2025-01-15T10:30:00+09:00\",value",
      "--zone", "UTC", "--iso8601"
    )

    status.should eq(0)
    # Should convert timestamp in middle field and preserve quotes
    output.strip.should eq("name,\"2025-01-15T01:30:00Z\",value")
  end

  it "handles multiple quoted timestamps on same line" do
    output, status = run_zone_with_input(
      "\"2025-01-15T10:30:00+09:00\" and \"2025-01-16T11:00:00+09:00\"",
      "--zone", "UTC", "--iso8601"
    )

    status.should eq(0)
    # Should convert both timestamps and preserve quotes
    output.strip.should eq("\"2025-01-15T01:30:00Z\" and \"2025-01-16T02:00:00Z\"")
  end

  it "preserves quotes around non-timestamp content" do
    output, status = run_zone_with_input(
      "\"not a timestamp\" but \"2025-01-15T10:30:00+09:00\" is",
      "--zone", "UTC", "--iso8601"
    )

    status.should eq(0)
    # Should preserve quotes around non-timestamp text
    output.should match(/"not a timestamp"/)
    # Should convert the actual timestamp
    output.strip.should eq("\"not a timestamp\" but \"2025-01-15T01:30:00Z\" is")
  end

  # Comma-separated field tests
  it "handles comma-separated field indices" do
    output, status = run_zone_with_input(
      "1736937000,1736940600,1736944200",
      "--field", "1,2,3", "--delimiter", ",", "--iso8601", "--zone", "UTC"
    )

    status.should eq(0)
    # All three fields should be converted to ISO8601 (no commas in output)
    fields = output.strip.split(",")
    fields.size.should eq(3)
    fields[0].should match(/2025-01-15T10:30:00/)
    fields[1].should match(/2025-01-15T11:30:00/)
    fields[2].should match(/2025-01-15T12:30:00/)
  end

  it "handles multiple --field flags" do
    output, status = run_zone_with_input(
      "1736937000,1736940600,data",
      "--field", "1", "--field", "2", "--delimiter", ",", "--iso8601", "--zone", "UTC"
    )

    status.should eq(0)
    # First two fields should be converted, third unchanged
    fields = output.strip.split(",")
    fields[0].should match(/2025-01-15T10:30:00/)
    fields[1].should match(/2025-01-15T11:30:00/)
    fields[2].should eq("data")
  end

  it "handles mixed comma-separated and multiple --field flags" do
    output, status = run_zone_with_input(
      "1736937000,1736940600,1736944200,data",
      "--field", "1,2", "--field", "3", "--delimiter", ",", "--iso8601", "--zone", "UTC"
    )

    status.should eq(0)
    # First three fields should be converted, fourth unchanged
    parts = output.strip.split(",")
    parts[0].should match(/2025-01-15T10:30:00/)
    parts[1].should match(/2025-01-15T11:30:00/)
    parts[2].should match(/2025-01-15T12:30:00/)
    parts[3].should eq("data")
  end

  it "handles comma-separated field names with headers" do
    input = "start,end,event\n1736937000,1736940600,meeting"
    output, status = run_zone_with_input(
      input,
      "--field", "start,end", "--delimiter", ",", "--headers", "--iso8601", "--zone", "UTC"
    )

    status.should eq(0)
    lines = output.strip.split("\n")
    lines[0].should match(/start.*end.*event/)  # Header preserved
    # Both timestamps converted (check as fields)
    fields = lines[1].split(",")
    fields[0].should match(/2025-01-15T10:30:00/)
    fields[1].should match(/2025-01-15T11:30:00/)
    fields[2].should eq("meeting")
  end

  # Output quoting tests
  it "quotes pretty output when delimiter is comma" do
    output, status = run_zone_with_input(
      "1736937000,data",
      "--field", "1", "--delimiter", ",", "--pretty"
    )

    status.should eq(0)
    # Pretty format contains comma, so it should be quoted
    output.strip.should match(/^"Jan 15, 2025[^"]*",data$/)
  end

  it "quotes pretty output when delimiter is space" do
    output, status = run_zone_with_input(
      "1736937000 data",
      "--field", "1", "--delimiter", "/\\s+/", "--pretty"
    )

    status.should eq(0)
    # Pretty format contains spaces, so it should be quoted
    output.strip.should match(/^"Jan 15, 2025[^"]*"\s+data$/)
  end

  it "does not quote ISO8601 output with comma delimiter" do
    output, status = run_zone_with_input(
      "1736937000,data",
      "--field", "1", "--delimiter", ",", "--iso8601", "--zone", "UTC"
    )

    status.should eq(0)
    # ISO8601 format has no commas, so no quoting needed
    output.strip.should_not match(/^"/)
    output.strip.should match(/^2025-01-15T10:30:00Z,data$/)
  end

  it "quotes unix output when delimiter is present in output" do
    # Unix timestamps are just numbers, unlikely to need quoting
    # but if they somehow did, they should be quoted
    output, status = run_zone_with_input(
      "2025-01-15T10:30:00Z,data",
      "--field", "1", "--delimiter", ",", "--unix"
    )

    status.should eq(0)
    # Unix timestamp is just numbers, no quoting needed
    output.strip.should match(/^1736937000,data$/)
  end

  # Silent mode tests
  it "suppresses warnings in silent mode" do
    output, status = run_zone_with_input(
      "a,b,c",
      "--field", "5", "--delimiter", ",", "--silent"
    )

    status.should eq(0)
    # Should not contain warning emoji or text
    output.should_not match(/⚠/)
    output.should_not match(/warn/i)
  end

  it "shows warnings by default" do
    output, status = run_zone_with_input(
      "a,b,c",
      "--field", "5", "--delimiter", ","
    )

    status.should eq(0)
    # Should contain warning
    output.should match(/⚠/)
  end

  it "silent mode works with verbose mode" do
    # --silent should override --verbose for user-facing warnings
    output, status = run_zone_with_input(
      "a,b,c",
      "--field", "5", "--delimiter", ",", "--silent", "--verbose"
    )

    status.should eq(0)
    # Should not show user warnings even with verbose
    output.should_not match(/⚠/)
    # But debug output may still appear (that's OK)
  end
end
