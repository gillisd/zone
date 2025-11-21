require "../spec_helper"

describe Zone do
  describe ".find" do
    it "finds exact timezone name" do
      tz = Zone.find("America/New_York")

      tz.should_not be_nil
      tz.try(&.name).should eq("America/New_York")
    end

    it "finds UTC" do
      tz = Zone.find("UTC")

      tz.should_not be_nil
      tz.try(&.name).should eq("UTC")
    end

    it "finds timezone with fuzzy matching (Tokyo)" do
      tz = Zone.find("tokyo")

      tz.should_not be_nil
      tz.try(&.name).should eq("Asia/Tokyo")
    end

    it "finds timezone with fuzzy matching (New York)" do
      tz = Zone.find("new york")

      tz.should_not be_nil
      tz.try(&.name).should match(/New_York/)
    end

    pending "finds US timezone" do
      # TZInfo data varies by environment - US/Eastern may not exist
      tz = Zone.find("eastern")

      tz.should_not be_nil
      tz.try(&.name).should match(/^US\//)
    end

    it "returns nil for invalid timezone" do
      tz = Zone.find("not_a_real_timezone_12345")

      tz.should be_nil
    end

    it "performs case insensitive search" do
      tz1 = Zone.find("Tokyo")
      tz2 = Zone.find("TOKYO")
      tz3 = Zone.find("tokyo")

      tz1.try(&.name).should eq(tz2.try(&.name))
      tz2.try(&.name).should eq(tz3.try(&.name))
    end
  end
end
