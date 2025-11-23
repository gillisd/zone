require "../spec_helper"

describe "Zone Pretty Format Parsing" do
  describe "Pretty3 ISO format (zone's default output)" do
    it "parses Pretty3 format with EDT" do
      timestamp = Zone::Timestamp.parse("2019-03-18 07:39 EDT")
      timestamp.time.year.should eq(2019)
      timestamp.time.month.should eq(3)
      timestamp.time.day.should eq(18)
      timestamp.time.hour.should eq(7)
      timestamp.time.minute.should eq(39)
    end

    it "parses Pretty3 format with UTC" do
      timestamp = Zone::Timestamp.parse("2025-10-08 23:30 UTC")
      timestamp.time.year.should eq(2025)
      timestamp.time.month.should eq(10)
      timestamp.time.day.should eq(8)
      timestamp.time.hour.should eq(23)
      timestamp.time.minute.should eq(30)
    end

    it "parses Pretty3 format with PST" do
      timestamp = Zone::Timestamp.parse("2020-01-15 14:22 PST")
      timestamp.time.year.should eq(2020)
      timestamp.time.month.should eq(1)
      timestamp.time.day.should eq(15)
      timestamp.time.hour.should eq(14)
      timestamp.time.minute.should eq(22)
    end
  end

  describe "Pretty1 12-hour format" do
    it "parses Pretty1 format with AM" do
      timestamp = Zone::Timestamp.parse("Mar 18, 2019 - 7:39 AM EDT")
      timestamp.time.year.should eq(2019)
      timestamp.time.month.should eq(3)
      timestamp.time.day.should eq(18)
      timestamp.time.hour.should eq(7)
      timestamp.time.minute.should eq(39)
    end

    it "parses Pretty1 format with PM" do
      timestamp = Zone::Timestamp.parse("Jan 15, 2025 - 3:45 PM UTC")
      timestamp.time.year.should eq(2025)
      timestamp.time.month.should eq(1)
      timestamp.time.day.should eq(15)
      timestamp.time.hour.should eq(15)
      timestamp.time.minute.should eq(45)
    end
  end

  describe "Pretty2 24-hour format" do
    it "parses Pretty2 format" do
      timestamp = Zone::Timestamp.parse("Mar 18, 2019 - 07:39 EDT")
      timestamp.time.year.should eq(2019)
      timestamp.time.month.should eq(3)
      timestamp.time.day.should eq(18)
      timestamp.time.hour.should eq(7)
      timestamp.time.minute.should eq(39)
    end

    it "parses Pretty2 format with different timezone" do
      timestamp = Zone::Timestamp.parse("Oct 08, 2025 - 23:30 UTC")
      timestamp.time.year.should eq(2025)
      timestamp.time.month.should eq(10)
      timestamp.time.day.should eq(8)
      timestamp.time.hour.should eq(23)
      timestamp.time.minute.should eq(30)
    end
  end

  describe "zone can parse its own output" do
    it "parses output from --pretty 3 (default)" do
      original = Zone::Timestamp.parse("2019-03-18T07:39:00Z")
      pretty_output = original.to_pretty(3)

      reparsed = Zone::Timestamp.parse(pretty_output)
      reparsed.time.year.should eq(2019)
      reparsed.time.month.should eq(3)
      reparsed.time.day.should eq(18)
    end

    it "parses output from --pretty 1" do
      original = Zone::Timestamp.parse("2019-03-18T07:39:00Z")
      pretty_output = original.to_pretty(1)

      reparsed = Zone::Timestamp.parse(pretty_output)
      reparsed.time.year.should eq(2019)
      reparsed.time.month.should eq(3)
    end

    it "parses output from --pretty 2" do
      original = Zone::Timestamp.parse("2019-03-18T07:39:00Z")
      pretty_output = original.to_pretty(2)

      reparsed = Zone::Timestamp.parse(pretty_output)
      reparsed.time.year.should eq(2019)
      reparsed.time.month.should eq(3)
    end
  end
end
