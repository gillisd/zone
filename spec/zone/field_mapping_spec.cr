require "../spec_helper"

describe Zone::FieldMapping do
  describe ".from_fields" do
    it "creates mapping from fields" do
      fields = ["name", "age", "city"]
      mapping = Zone::FieldMapping.from_fields(fields)

      mapping.should be_a(Zone::FieldMapping)
      mapping["name"].should eq(0)
      mapping["age"].should eq(1)
      mapping["city"].should eq(2)
    end
  end

  describe ".numeric" do
    it "creates numeric-only mapping" do
      mapping = Zone::FieldMapping.numeric

      mapping.should be_a(Zone::FieldMapping)
      mapping.has_names?.should be_false
      mapping.names.should be_empty
    end
  end

  describe "#resolve" do
    it "resolves field names" do
      mapping = Zone::FieldMapping.from_fields(["name", "timestamp", "value"])

      mapping.resolve("timestamp").should eq(1)
    end

    it "converts integer to zero-based index" do
      mapping = Zone::FieldMapping.numeric

      mapping.resolve(1).should eq(0)
      mapping.resolve(2).should eq(1)
      mapping.resolve(10).should eq(9)
    end

    it "handles numeric strings" do
      mapping = Zone::FieldMapping.numeric

      mapping["1"].should eq(0)
      mapping["2"].should eq(1)
    end
  end

  describe "bracket operator" do
    it "works as alias for resolve" do
      mapping = Zone::FieldMapping.from_fields(["a", "b", "c"])

      mapping["a"].should eq(0)
      mapping[2].should eq(1)
    end
  end

  describe "#resolve with missing field" do
    it "raises error for missing field name" do
      mapping = Zone::FieldMapping.from_fields(["a", "b"])

      expect_raises(KeyError, /not found/) do
        mapping.resolve("nonexistent")
      end
    end
  end

  describe "#names" do
    it "returns field names" do
      fields = ["foo", "bar", "baz"]
      mapping = Zone::FieldMapping.from_fields(fields)

      mapping.names.should eq(fields)
      mapping.names.should contain("foo")
      mapping.names.should contain("bar")
    end

    it "returns empty array for numeric mapping" do
      mapping = Zone::FieldMapping.numeric

      mapping.names.should be_empty
    end
  end

  describe "#has_names?" do
    it "returns true when mapping has names" do
      with_names = Zone::FieldMapping.from_fields(["a"])
      numeric = Zone::FieldMapping.numeric

      with_names.has_names?.should be_true
      numeric.has_names?.should be_false
    end
  end
end
