require "../spec_helper"

# Helper methods for running zone CLI
def run_zone(zone_bin : String, *args)
  io = IO::Memory.new
  error_io = IO::Memory.new
  status = Process.run(zone_bin, args: args.to_a, output: io, error: error_io)
  output = io.to_s + error_io.to_s
  {output, status.exit_code}
end

def run_zone_with_input(zone_bin : String, input : String, *args)
  io = IO::Memory.new
  error_io = IO::Memory.new
  process = Process.new(zone_bin, args: args.to_a, input: Process::Redirect::Pipe, output: io, error: error_io)
  process.input.print(input)
  process.input.close
  status = process.wait
  output = io.to_s + error_io.to_s
  {output, status.exit_code}
end

describe "CLI Integration" do
  zone_bin = File.expand_path("../../bin/zone", __DIR__)

  it "converts timestamp to UTC" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--utc", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T10:30:00/)
  end

  it "converts timestamp to specific zone" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--zone", "Tokyo", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T19:30:00/)
  end

  it "converts unix timestamp" do
    output, status = run_zone(zone_bin, "1736937000", "--zone", "UTC")

    status.should eq(0)
    output.should match(/Jan 15, 2025/)
  end

  it "outputs pretty format" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--pretty")

    status.should eq(0)
    output.should match(/Jan/)
    output.should match(/\d{1,2}:\d{2} [AP]M/)
  end

  it "outputs unix format" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--unix")

    status.should eq(0)
    output.should eq("1736937000\n")
  end

  it "supports custom strftime format" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--strftime", "%Y-%m-%d")

    status.should eq(0)
    output.should eq("2025-01-15\n")
  end

  it "extracts field by index" do
    output, status = run_zone_with_input(
      zone_bin,
      "test 1736937000 data",
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    output.should match(/test\s+1736937000\s+data/)
  end

  it "extracts field with tab delimiter" do
    output, status = run_zone_with_input(
      zone_bin,
      "foo\t1736937000\tbar",
      "--field", "2", "--delimiter", "\t", "--unix"
    )

    status.should eq(0)
    output.should eq("foo\t1736937000\tbar\n")
  end

  it "extracts field with custom delimiter" do
    output, status = run_zone_with_input(
      zone_bin,
      "foo|1736937000|bar",
      "--field", "2", "--delimiter", "|", "--unix"
    )

    status.should eq(0)
    output.should eq("foo|1736937000|bar\n")
  end

  it "processes field with headers" do
    input = "timestamp,value,name\n1736937000,100,test"
    output, status = run_zone_with_input(
      zone_bin,
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
    output, status = run_zone_with_input(
      zone_bin,
      input,
      "--pretty"
    )

    status.should eq(0)
    lines = output.lines
    lines.size.should eq(3)
    lines.each do |line|
      line.should match(/Jan/)
    end
  end

  it "performs fuzzy timezone search" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--zone", "tokyo", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T19:30:00/)
  end

  it "converts to local timezone" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--local")

    status.should eq(0)
    output.should match(/Jan 15, 2025/)
  end

  it "shows verbose logging" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--verbose", "--utc")

    status.should eq(0)
    output.should match(/DEBUG/)
  end

  it "returns error for invalid timestamp" do
    output, status = run_zone(zone_bin, "not_a_valid_timestamp")

    status.should_not eq(0)
    output.should match(/Could not parse time/)
  end

  it "returns error for invalid timezone" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "--zone", "NotARealTimezone12345")

    status.should_not eq(0)
    output.should match(/Could not find timezone/)
  end

  it "returns error for invalid pretty format" do
    output, status = run_zone(zone_bin, "2025-01-15T10:30:00Z", "-p4")

    status.should_not eq(0)
    output.should match(/Invalid pretty format -p4/)
    output.should match(/must be 1, 2, or 3/)
  end

  it "combines field and zone conversion" do
    output, status = run_zone_with_input(
      zone_bin,
      "data,1736937000,more",
      "--field", "2", "--zone", "Tokyo", "--delimiter", ",", "--iso8601"
    )

    status.should eq(0)
    output.should match(/2025-01-15T19:30:00/)
    output.should match(/\+09:00/)
  end

  it "parses date command format with spaces" do
    output, status = run_zone(zone_bin, "Wed Nov 12 19:13:17 UTC 2025", "--utc", "--iso8601")

    status.should eq(0)
    output.should match(/2025-11-12T19:13:17/)
  end

  it "parses piped date format" do
    output, status = run_zone_with_input(
      zone_bin,
      "Wed Nov 12 19:13:17 UTC 2025",
      "--utc", "--iso8601"
    )

    status.should eq(0)
    output.should match(/2025-11-12T19:13:17/)
  end

  it "parses date format with timezone abbreviation" do
    output, status = run_zone(zone_bin, "Wed Nov 12 14:11:40 EST 2025", "--utc")

    status.should eq(0)
    output.should match(/Nov 12, 2025/)
  end

  it "parses multiline date formats" do
    input = "Wed Nov 12 10:30:00 UTC 2025\nThu Nov 13 11:45:00 UTC 2025"
    output, status = run_zone_with_input(zone_bin, input, "--utc", "--iso8601")

    status.should eq(0)
    lines = output.lines
    lines.size.should eq(2)
    lines[0].should match(/2025-11-12T10:30:00/)
    lines[1].should match(/2025-11-13T11:45:00/)
  end

  it "does not trigger field processing by default" do
    # Ensure spaces in timestamp don't cause field splitting
    output, status = run_zone(zone_bin, "2025-01-15 10:30:00", "--utc", "--iso8601")

    status.should eq(0)
    output.should match(/2025-01-15T10:30:00/)
  end

  it "works with explicit field 1" do
    output, status = run_zone_with_input(
      zone_bin,
      "1736937000 extra data",
      "--field", "1", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    output.should match(/1736937000\s+extra\s+data/)
  end

  it "uses current time with no arguments" do
    # When STDIN is a tty (interactive), zone with no args uses Time.now
    # In automated tests, STDIN is not a tty, so we skip this test
    pending "Cannot test TTY behavior in automated tests"
  end

  it "processes multiple timestamp arguments" do
    output, status = run_zone(
      zone_bin,
      "2025-01-15T10:30:00Z",
      "2025-01-16T11:00:00Z",
      "--utc", "--iso8601"
    )

    status.should eq(0)
    lines = output.lines
    lines.size.should eq(2)
    lines[0].should match(/2025-01-15T10:30:00/)
    lines[1].should match(/2025-01-16T11:00:00/)
  end

  it "passes through empty line input" do
    output, status = run_zone_with_input(zone_bin, "\n", "--utc")

    status.should eq(0)
    # Piped empty line passes through silently, no warning
    output.should eq("\n")
  end

  it "handles mixed valid and invalid timestamps" do
    input = "2025-01-15T10:30:00Z\ninvalid\n2025-01-16T10:30:00Z"
    output, status = run_zone_with_input(zone_bin, input, "--utc", "--iso8601")

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
      zone_bin,
      "a,b,c",
      "--field", "5", "--delimiter", ","
    )

    status.should eq(0)
    output.should match(/⚠/)
  end

  it "returns error for nonexistent field name" do
    output, status = run_zone_with_input(
      zone_bin,
      "a,b,c",
      "--field", "nonexistent", "--delimiter", ","
    )

    status.should_not eq(0)
    output.should match(/Error/)
  end

  it "handles headers only input" do
    output, status = run_zone_with_input(
      zone_bin,
      "name,timestamp,value",
      "--field", "timestamp", "--delimiter", ",", "--headers"
    )

    status.should eq(0)
    # Header line is output even when there's no data
    output.strip.should match(/name.*timestamp.*value/)
  end

  it "preserves timezone offset" do
    # Critical regression test: ensure timezone offset is not stripped during pattern matching
    # Bug was: "2025-01-15 16:30:00 -0500" would match as "2025-01-15 16:30:00" (no offset)
    # and be parsed as UTC, resulting in 5-hour error when converting to EST
    output, status = run_zone(zone_bin, "2025-01-15 16:30:00 -0500", "--zone", "America/New_York")

    status.should eq(0)
    # Should show 4:30 PM (16:30), not 11:30 AM (5 hours earlier)
    output.should match(/4:30 PM/)
    output.should match(/EST/)
  end

  it "preserves timezone offset to iso8601" do
    # Verify timezone offset is preserved in parsing and conversion
    output, status = run_zone(zone_bin, "2025-01-15 16:30:00 -0500", "--iso8601", "--zone", "UTC")

    status.should eq(0)
    # -0500 is EST, which is UTC+5, so 16:30 EST = 21:30 UTC
    output.should match(/2025-01-15T21:30:00/)
  end
end
