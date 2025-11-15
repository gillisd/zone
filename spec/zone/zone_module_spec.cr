require "../test_helper"

describe Zone do
  describe ".find" do
    it "finds exact timezone name" do
      tz = Zone.find("America/New_York")

      tz.should_not be_nil
      tz.should be_a(Time::Location)
    end

    it "finds UTC" do
      tz = Zone.find("UTC")

      tz.should_not be_nil
      tz.should be_a(Time::Location)
    end

    it "finds fuzzy tokyo" do
      tz = Zone.find("tokyo")

      tz.should_not be_nil
      tz.should be_a(Time::Location)
    end

    it "finds fuzzy new york" do
      tz = Zone.find("new york")

      tz.should_not be_nil
      tz.should be_a(Time::Location)
    end

    pending "finds us timezone" do
      # Skip: US/ timezones may not exist in all TZData installations
      tz = Zone.find("eastern")

      tz.should_not be_nil
    end

    it "returns nil for invalid timezone" do
      tz = Zone.find("not_a_real_timezone_12345")

      tz.should be_nil
    end

    it "is case insensitive" do
      tz1 = Zone.find("Tokyo")
      tz2 = Zone.find("TOKYO")
      tz3 = Zone.find("tokyo")

      tz1.should_not be_nil
      tz2.should_not be_nil
      tz3.should_not be_nil
    end
  end
end
