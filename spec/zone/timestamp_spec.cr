require "../spec_helper"

describe Zone::Timestamp do
  describe ".parse" do
    it "parses Time object" do
      time = Time.utc
      timestamp = Zone::Timestamp.parse(time.to_s)

      timestamp.should be_a(Zone::Timestamp)
    end

    it "parses unix timestamp seconds" do
      # Unix epoch for 2025-01-15 10:30:00 UTC
      timestamp = Zone::Timestamp.parse("1736937000")

      timestamp.time.to_unix.should eq(1736937000)
    end

    it "parses unix timestamp milliseconds" do
      # 13 digits - milliseconds precision
      timestamp = Zone::Timestamp.parse("1736937000000")

      timestamp.time.to_unix.should eq(1736937000)
    end

    it "parses ISO8601 string" do
      timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")

      timestamp.time.year.should eq(2025)
      timestamp.time.month.should eq(1)
      timestamp.time.day.should eq(15)
      timestamp.time.hour.should eq(10)
      timestamp.time.minute.should eq(30)
    end

    it "parses relative time ago" do
      timestamp = Zone::Timestamp.parse("5 minutes ago")
      diff = Time.utc - timestamp.time

      diff.total_seconds.should be_close(300.0, 2.0)
    end

    it "parses relative time from now" do
      timestamp = Zone::Timestamp.parse("1 hour from now")
      diff = timestamp.time - Time.utc

      diff.total_seconds.should be_close(3600.0, 2.0)
    end

    it "raises error for invalid input" do
      expect_raises(ArgumentError, /Could not parse time/) do
        Zone::Timestamp.parse("not a valid timestamp")
      end
    end
  end

  describe "#in_zone" do
    it "returns new timestamp in specified zone" do
      original = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
      tokyo = original.in_zone("Tokyo")

      tokyo.should be_a(Zone::Timestamp)
      tokyo.should_not be(original)
      tokyo.zone.should eq("Tokyo")
    end
  end

  describe "#in_utc" do
    it "returns new timestamp in UTC" do
      local = Zone::Timestamp.parse(Time.local.to_s)
      utc = local.in_utc

      utc.should be_a(Zone::Timestamp)
      utc.zone.should eq("UTC")
    end
  end

  describe "#in_local" do
    it "returns new timestamp in local timezone" do
      utc = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
      local = utc.in_local

      local.should be_a(Zone::Timestamp)
      local.zone.should eq("local")
    end
  end

  describe "#to_iso8601" do
    it "formats as ISO8601" do
      timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
      formatted = timestamp.to_iso8601

      formatted.should match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end

  describe "#to_unix" do
    it "returns unix timestamp" do
      timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
      unix = timestamp.to_unix

      unix.should be_a(Int64)
      unix.should eq(1736937000)
    end
  end

  describe "#to_pretty" do
    it "formats in pretty format" do
      timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
      pretty = timestamp.to_pretty

      pretty.should match(/Jan \d+/)
      pretty.should match(/\d{1,2}:\d{2} [AP]M/)
    end
  end

  describe "#strftime" do
    it "formats with custom format" do
      timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
      formatted = timestamp.strftime("%Y-%m-%d")

      formatted.should eq("2025-01-15")
    end
  end

  describe "chainable operations" do
    it "chains operations together" do
      result = Zone::Timestamp
        .parse("2025-01-15T10:30:00Z")
        .in_zone("Tokyo")
        .to_iso8601

      result.should be_a(String)
      result.should match(/\+09:00/)
    end
  end
end
