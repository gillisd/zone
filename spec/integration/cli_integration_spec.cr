require "../integration_helper"

describe "CLI Integration" do
  include IntegrationHelper

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

  it "handles piped input with field extraction" do
    output, status = run_zone_with_input(
      "test 1736937000 data",
      "--field", "2", "--delimiter", "/\\s+/", "--unix"
    )

    status.should eq(0)
    output.should match(/test\s+1736937000\s+data/)
  end

  it "processes CSV with headers" do
    input = "timestamp,value,name\n1736937000,100,test"
    output, status = run_zone_with_input(
      input,
      "--field", "timestamp", "--delimiter", ",", "--headers", "--unix"
    )

    status.should eq(0)
    lines = output.strip.split("\n")
    lines.size.should eq(2)
    lines[0].should match(/timestamp/)
    lines[1].should match(/1736937000/)
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
end
