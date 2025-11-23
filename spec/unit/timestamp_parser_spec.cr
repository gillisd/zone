require "../spec_helper"

describe Zone::TimestampParser do
  describe ".parse" do
    it "parses ISO8601 with timezone" do
      time = Zone::TimestampParser.parse("2025-01-15T10:30:00+05:30")
      time.should be_a(Time)
      time.year.should eq(2025)
      time.month.should eq(1)
      time.day.should eq(15)
    end

    it "parses ISO8601 Zulu time" do
      time = Zone::TimestampParser.parse("2025-01-15T10:30:00Z")
      time.should be_a(Time)
      time.year.should eq(2025)
    end

    it "parses 12-hour format with timezone" do
      time = Zone::TimestampParser.parse("2025-01-15 10:30:00 PM UTC")
      time.should be_a(Time)
      time.hour.should eq(22)
    end

    it "parses compact date format" do
      time = Zone::TimestampParser.parse("20251121")
      time.should be_a(Time)
      time.year.should eq(2025)
      time.month.should eq(11)
      time.day.should eq(21)
    end

    it "parses unix timestamp" do
      time = Zone::TimestampParser.parse("1736937000")
      time.should be_a(Time)
    end

    it "parses unix timestamp milliseconds" do
      time = Zone::TimestampParser.parse("1736937000000")
      time.should be_a(Time)
    end

    it "parses relative time" do
      time = Zone::TimestampParser.parse("2 hours ago")
      time.should be_a(Time)
    end

    it "raises ArgumentError for invalid input" do
      expect_raises(ArgumentError, /Could not parse time/) do
        Zone::TimestampParser.parse("not a valid timestamp")
      end
    end

    it "uses fallback parsing for standard formats" do
      time = Zone::TimestampParser.parse("2025-01-15 10:30:00")
      time.should be_a(Time)
    end
  end
end
