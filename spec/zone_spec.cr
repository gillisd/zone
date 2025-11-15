require "./test_helper"

describe Zone do
  it "has a version number" do
    Zone::VERSION.should_not be_nil
    Zone::VERSION.should eq("0.1.1")
  end
end
