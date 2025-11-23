require "../spec_helper"

describe Zone::TimestampPattern do
  describe "ISO8601WithTzPattern" do
    pattern = Zone::ISO8601WithTzPattern.new

    it "returns correct name" do
      pattern.name.should eq("ISO8601_WITH_TZ")
    end

    it "returns correct pattern" do
      pattern.pattern.should be_a(Regex)
    end

    it "matches valid ISO8601 with timezone" do
      pattern.matches?("2025-01-15T10:30:00+05:30").should be_true
      pattern.matches?("2025-01-15T10:30:00-08:00").should be_true
    end

    it "does not match invalid formats" do
      pattern.matches?("2025-01-15").should be_false
      pattern.matches?("not a timestamp").should be_false
    end

    it "parses valid ISO8601 with timezone" do
      time = pattern.parse("2025-01-15T10:30:00+05:30")
      time.should be_a(Time)
      time.not_nil!.year.should eq(2025)
      time.not_nil!.month.should eq(1)
      time.not_nil!.day.should eq(15)
    end

    it "returns nil for invalid input" do
      pattern.parse("not a timestamp").should be_nil
    end
  end

  describe "ISO8601ZuluPattern" do
    pattern = Zone::ISO8601ZuluPattern.new

    it "returns correct name" do
      pattern.name.should eq("ISO8601_ZULU")
    end

    it "matches valid ISO8601 with Z suffix" do
      pattern.matches?("2025-01-15T10:30:00Z").should be_true
      pattern.matches?("2025-01-15T10:30:00.123Z").should be_true
    end

    it "parses valid ISO8601 Zulu time" do
      time = pattern.parse("2025-01-15T10:30:00Z")
      time.should be_a(Time)
      time.not_nil!.year.should eq(2025)
    end
  end

  describe "CompactDatePattern" do
    pattern = Zone::CompactDatePattern.new

    it "returns correct name" do
      pattern.name.should eq("COMPACT_DATE")
    end

    it "matches valid compact dates" do
      pattern.matches?("20251121").should be_true
      pattern.matches?("19990101").should be_true
    end

    it "does not match invalid compact dates" do
      pattern.matches?("2025").should be_false
      pattern.matches?("20251301").should be_false # Invalid month
    end

    it "parses valid compact date" do
      time = pattern.parse("20251121")
      time.should be_a(Time)
      time.not_nil!.year.should eq(2025)
      time.not_nil!.month.should eq(11)
      time.not_nil!.day.should eq(21)
    end
  end

  describe "TwelveHourWithTzPattern" do
    pattern = Zone::TwelveHourWithTzPattern.new

    it "returns correct name" do
      pattern.name.should eq("12HR_WITH_TZ")
    end

    it "matches valid 12-hour format with timezone" do
      pattern.matches?("2025-11-15 03:54:41 PM EST").should be_true
      pattern.matches?("2025-01-01 12:00:00 AM UTC").should be_true
    end

    it "parses valid 12-hour time" do
      time = pattern.parse("2025-01-15 10:30:00 PM UTC")
      time.should be_a(Time)
      time.not_nil!.hour.should eq(22) # 10 PM = 22:00
    end
  end
end
