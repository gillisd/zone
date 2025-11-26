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

    it "handles 12 AM correctly (midnight)" do
      time = pattern.parse("2025-01-15 12:00:00 AM UTC")
      time.not_nil!.hour.should eq(0)
    end

    it "handles 12 PM correctly (noon)" do
      time = pattern.parse("2025-01-15 12:00:00 PM UTC")
      time.not_nil!.hour.should eq(12)
    end

    it "returns nil for invalid AM/PM format" do
      pattern.parse("2025-01-15 13:00:00 PM UTC").should be_nil
    end
  end

  describe "UnixTimestampPattern" do
    pattern = Zone::UnixTimestampPattern.new

    it "returns correct name" do
      pattern.name.should eq("UNIX_TIMESTAMP")
    end

    it "parses 10-digit unix timestamp (seconds)" do
      time = pattern.parse("1736937000")
      time.should be_a(Time)
      time.not_nil!.to_unix.should eq(1736937000)
    end

    it "parses 13-digit unix timestamp (milliseconds)" do
      time = pattern.parse("1736937000000")
      time.should be_a(Time)
      time.not_nil!.to_unix.should eq(1736937000)
    end

    it "parses 16-digit unix timestamp (microseconds)" do
      time = pattern.parse("1736937000000000")
      time.should be_a(Time)
      time.not_nil!.to_unix.should eq(1736937000)
    end

    it "parses decimal unix timestamp" do
      time = pattern.parse("1736937000.123")
      time.should be_a(Time)
      time.not_nil!.to_unix.should eq(1736937000)
    end

    it "validates timestamp is in valid range" do
      pattern.valid?("1000000000").should be_true
      pattern.valid?("2100000000").should be_true
      pattern.valid?("999999999").should be_false  # Too old
    end

    it "returns nil for non-numeric input" do
      pattern.parse("not-a-number").should be_nil
    end
  end

  describe "RelativeTimePattern" do
    pattern = Zone::RelativeTimePattern.new

    it "returns correct name" do
      pattern.name.should eq("RELATIVE_TIME")
    end

    it "matches relative time formats" do
      pattern.matches?("2 hours ago").should be_true
      pattern.matches?("5 days from now").should be_true
      pattern.matches?("1 week ago").should be_true
    end

    it "parses 'hours ago'" do
      time = pattern.parse("2 hours ago")
      time.should be_a(Time)
    end

    it "parses 'days from now'" do
      time = pattern.parse("5 days from now")
      time.should be_a(Time)
    end

    it "does not match invalid relative formats" do
      pattern.matches?("2 hours before").should be_false
      pattern.matches?("next week").should be_false
    end
  end

  describe "GitLogPattern" do
    pattern = Zone::GitLogPattern.new

    it "returns correct name" do
      pattern.name.should eq("GIT_LOG")
    end

    it "matches git log format" do
      pattern.matches?("Mon Jan 15 10:30:00 2025 +0000").should be_true
      pattern.matches?("Fri Dec 25 15:45:30 2020 -0800").should be_true
    end

    it "parses git log format" do
      time = pattern.parse("Mon Jan 15 10:30:00 2025 +0000")
      time.should be_a(Time)
      time.not_nil!.year.should eq(2025)
      time.not_nil!.month.should eq(1)
      time.not_nil!.day.should eq(15)
    end

    it "returns nil for malformed git format" do
      pattern.parse("Invalid Git Log").should be_nil
    end
  end

  describe "DateCommandPattern" do
    pattern = Zone::DateCommandPattern.new

    it "returns correct name" do
      pattern.name.should eq("DATE_COMMAND")
    end

    it "matches date command format" do
      pattern.matches?("Mon Jan 15 10:30:00 EST 2025").should be_true
      pattern.matches?("Fri Dec 25 15:45:30 PST 2020").should be_true
    end

    it "parses date command format" do
      time = pattern.parse("Mon Jan 15 10:30:00 UTC 2025")
      time.should be_a(Time)
      time.not_nil!.year.should eq(2025)
    end

    it "handles different timezones" do
      time = pattern.parse("Mon Jan 15 10:30:00 EST 2025")
      time.should be_a(Time)
    end
  end

  describe "ISO8601SpaceWithOffsetPattern" do
    pattern = Zone::ISO8601SpaceWithOffsetPattern.new

    it "returns correct name" do
      pattern.name.should eq("ISO8601_SPACE_WITH_OFFSET")
    end

    it "matches space-separated ISO8601 with offset" do
      pattern.matches?("2025-01-15 10:30:00 +0530").should be_true
      pattern.matches?("2025-01-15 10:30:00 -0800").should be_true
    end

    it "parses with positive offset" do
      time = pattern.parse("2025-01-15 10:30:00 +0530")
      time.should be_a(Time)
    end

    it "parses with negative offset" do
      time = pattern.parse("2025-01-15 10:30:00 -0800")
      time.should be_a(Time)
    end
  end

  describe "ISO8601SpacePattern" do
    pattern = Zone::ISO8601SpacePattern.new

    it "returns correct name" do
      pattern.name.should eq("ISO8601_SPACE")
    end

    it "matches space-separated ISO8601 without offset" do
      pattern.matches?("2025-01-15 10:30:00").should be_true
    end

    it "does not match with offset" do
      pattern.matches?("2025-01-15 10:30:00 +0000").should be_false
    end

    it "parses to local time" do
      time = pattern.parse("2025-01-15 10:30:00")
      time.should be_a(Time)
      time.not_nil!.year.should eq(2025)
    end
  end

  describe "DateWithOffsetPattern" do
    pattern = Zone::DateWithOffsetPattern.new

    it "returns correct name" do
      pattern.name.should eq("DATE_WITH_OFFSET")
    end

    it "matches date with offset" do
      pattern.matches?("1901-01-01+19:07Z").should be_true
      pattern.matches?("2025-12-31-05:00").should be_true
    end

    it "parses date with positive offset" do
      time = pattern.parse("2025-01-01+09:00")
      time.should be_a(Time)
      time.not_nil!.year.should eq(2025)
      time.not_nil!.month.should eq(1)
      time.not_nil!.day.should eq(1)
    end

    it "parses date with negative offset" do
      time = pattern.parse("2025-01-01-08:00")
      time.should be_a(Time)
    end

    it "parses historical date with offset" do
      time = pattern.parse("1901-01-01+19:07Z")
      time.should be_a(Time)
      time.not_nil!.year.should eq(1901)
    end
  end

  describe "Edge Cases and Error Handling" do
    describe "CompactDatePattern edge cases" do
      pattern = Zone::CompactDatePattern.new

      it "rejects invalid month 13" do
        pattern.matches?("20251301").should be_false
      end

      it "rejects invalid day 32" do
        pattern.matches?("20250132").should be_false
      end

      it "accepts leap year Feb 29" do
        pattern.matches?("20200229").should be_true
      end

      it "rejects year before 1970" do
        pattern.matches?("19690101").should be_false
      end

      it "accepts year 1970" do
        pattern.matches?("19700101").should be_true
      end

      it "accepts year 2099" do
        pattern.matches?("20991231").should be_true
      end
    end

    describe "Timezone edge cases" do
      it "handles UTC timezone" do
        pattern = Zone::TwelveHourWithTzPattern.new
        time = pattern.parse("2025-01-15 10:30:00 AM UTC")
        time.should be_a(Time)
      end

      it "handles EST timezone" do
        pattern = Zone::Pretty3IsoPattern.new
        time = pattern.parse("2025-01-15 10:30 EST")
        time.should be_a(Time)
      end

      it "handles PST timezone" do
        pattern = Zone::Pretty3IsoPattern.new
        time = pattern.parse("2025-01-15 10:30 PST")
        time.should be_a(Time)
      end

      it "returns nil for invalid timezone" do
        pattern = Zone::Pretty3IsoPattern.new
        time = pattern.parse("2025-01-15 10:30 INVALID")
        # Invalid timezone causes parse to fail
        time.should be_nil
      end
    end

    describe "Boundary conditions" do
      it "handles midnight" do
        pattern = Zone::ISO8601SpacePattern.new
        time = pattern.parse("2025-01-15 00:00:00")
        time.not_nil!.hour.should eq(0)
      end

      it "handles end of day" do
        pattern = Zone::ISO8601SpacePattern.new
        time = pattern.parse("2025-01-15 23:59:59")
        time.not_nil!.hour.should eq(23)
        time.not_nil!.minute.should eq(59)
        time.not_nil!.second.should eq(59)
      end

      it "handles year boundaries" do
        pattern = Zone::ISO8601ZuluPattern.new
        time = pattern.parse("2024-12-31T23:59:59Z")
        time.not_nil!.year.should eq(2024)
        time.not_nil!.month.should eq(12)
        time.not_nil!.day.should eq(31)
      end
    end

    describe "Invalid input handling" do
      it "returns nil for empty string" do
        pattern = Zone::ISO8601WithTzPattern.new
        pattern.parse("").should be_nil
      end

      it "returns nil for garbage input" do
        pattern = Zone::CompactDatePattern.new
        pattern.parse("garbage123").should be_nil
      end

      it "returns nil for partial match" do
        pattern = Zone::ISO8601ZuluPattern.new
        pattern.parse("2025-01-15T").should be_nil
      end

      it "handles malformed unix timestamp" do
        pattern = Zone::UnixTimestampPattern.new
        pattern.parse("abc123def").should be_nil
      end
    end

    describe "Pretty format edge cases" do
      it "Pretty1 handles single digit hours" do
        pattern = Zone::Pretty1TwelveHourPattern.new
        time = pattern.parse("Jan 15, 2025 - 3:45 AM UTC")
        time.not_nil!.hour.should eq(3)
      end

      it "Pretty2 requires two digit hours" do
        pattern = Zone::Pretty2TwentyFourHourPattern.new
        time = pattern.parse("Jan 15, 2025 - 03:45 UTC")
        time.should be_a(Time)
      end

      it "Pretty3 handles abbreviated timezone" do
        pattern = Zone::Pretty3IsoPattern.new
        time = pattern.parse("2025-01-15 10:30 UTC")
        time.should be_a(Time)
      end

      it "Pretty3 handles 4-letter timezone" do
        pattern = Zone::Pretty3IsoPattern.new
        time = pattern.parse("2025-01-15 10:30 NZDT")
        time.should be_a(Time)
      end
    end

    describe "Quote handling" do
      it "matches timestamp inside double quotes" do
        pattern = Zone::ISO8601ZuluPattern.new
        # Word boundary \b matches between quote and digit
        pattern.matches?("\"2025-01-15T10:30:00Z\"").should be_true
      end

      it "matches timestamp inside single quotes" do
        pattern = Zone::ISO8601WithTzPattern.new
        pattern.matches?("'2025-01-15T10:30:00+09:00'").should be_true
      end

      it "matches unix timestamp inside quotes" do
        pattern = Zone::UnixTimestampPattern.new
        pattern.matches?("\"1736937000\"").should be_true
      end

      it "matches timestamp in quoted CSV field" do
        pattern = Zone::ISO8601ZuluPattern.new
        pattern.matches?("name,\"2025-01-15T10:30:00Z\",value").should be_true
      end

      it "matches compact date inside quotes" do
        pattern = Zone::CompactDatePattern.new
        pattern.matches?("\"20251121\"").should be_true
      end

      it "matches git log format inside quotes" do
        pattern = Zone::GitLogPattern.new
        pattern.matches?("\"Mon Jan 15 10:30:00 2025 +0000\"").should be_true
      end

      it "matches date command format inside quotes" do
        pattern = Zone::DateCommandPattern.new
        pattern.matches?("\"Mon Jan 15 10:30:00 EST 2025\"").should be_true
      end

      it "matches 12-hour format inside quotes" do
        pattern = Zone::TwelveHourWithTzPattern.new
        pattern.matches?("\"2025-01-15 03:54:41 PM EST\"").should be_true
      end
    end
  end
end

describe Zone::TimestampPatterns do
  describe ".replace_all quote preservation" do
    it "preserves double quotes around ISO8601 timestamp" do
      result = Zone::TimestampPatterns.replace_all("\"2025-01-15T10:30:00Z\"") do |match, _|
        "REPLACED"
      end
      result.should eq("\"REPLACED\"")
    end

    it "preserves single quotes around ISO8601 timestamp" do
      result = Zone::TimestampPatterns.replace_all("'2025-01-15T10:30:00+09:00'") do |match, _|
        "REPLACED"
      end
      result.should eq("'REPLACED'")
    end

    it "preserves quotes around unix timestamp" do
      result = Zone::TimestampPatterns.replace_all("\"1736937000\"") do |match, _|
        "REPLACED"
      end
      result.should eq("\"REPLACED\"")
    end

    it "preserves quotes in CSV field context" do
      result = Zone::TimestampPatterns.replace_all("name,\"2025-01-15T10:30:00Z\",value") do |match, _|
        "REPLACED"
      end
      result.should eq("name,\"REPLACED\",value")
    end

    it "preserves multiple quoted timestamps" do
      input = "\"2025-01-15T10:30:00Z\" and \"2025-01-16T11:00:00Z\""
      result = Zone::TimestampPatterns.replace_all(input) do |match, _|
        "REPLACED"
      end
      result.should eq("\"REPLACED\" and \"REPLACED\"")
    end

    it "preserves quotes around non-timestamp content" do
      input = "\"not a timestamp\" but \"2025-01-15T10:30:00Z\" is"
      result = Zone::TimestampPatterns.replace_all(input) do |match, _|
        "REPLACED"
      end
      result.should eq("\"not a timestamp\" but \"REPLACED\" is")
    end

    it "handles mixed quoted and unquoted timestamps" do
      input = "2025-01-15T10:30:00Z and \"2025-01-16T11:00:00Z\""
      result = Zone::TimestampPatterns.replace_all(input) do |match, _|
        "REPLACED"
      end
      result.should eq("REPLACED and \"REPLACED\"")
    end

    it "preserves quotes around compact date" do
      result = Zone::TimestampPatterns.replace_all("\"20251121\"") do |match, _|
        "REPLACED"
      end
      result.should eq("\"REPLACED\"")
    end
  end
end
