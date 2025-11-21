require "./spec_helper"

describe Zone do
  it "has a version number" do
    Zone::VERSION.should_not be_nil
  end
end
