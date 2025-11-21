require "../spec_helper"

describe Zone::FieldLine do
  describe ".parse" do
    it "parses simple comma delimited line" do
      line = Zone::FieldLine.parse("foo,bar,baz", delimiter: ",")

      line.should be_a(Zone::FieldLine)
      line.fields.should eq(["foo", "bar", "baz"])
    end

    it "parses tab delimited line" do
      line = Zone::FieldLine.parse("foo\tbar\tbaz", delimiter: "\t")

      line.fields.should eq(["foo", "bar", "baz"])
    end

    it "parses whitespace delimited line" do
      line = Zone::FieldLine.parse("foo  bar   baz", delimiter: "/\\s+/")

      line.fields.should eq(["foo", "bar", "baz"])
    end

    it "parses with explicit delimiter" do
      line = Zone::FieldLine.parse("foo|bar|baz", delimiter: "|")

      line.fields.should eq(["foo", "bar", "baz"])
    end

    it "parses with mapping" do
      mapping = Zone::FieldMapping.from_fields(["name", "value"])
      line = Zone::FieldLine.parse("test,100", delimiter: ",", mapping: mapping)

      line["name"].should eq("test")
      line["value"].should eq("100")
    end
  end

  describe "bracket access" do
    it "accesses by index" do
      line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

      line[1].should eq("a")
      line[2].should eq("b")
      line[3].should eq("c")
    end

    it "accesses by name" do
      mapping = Zone::FieldMapping.from_fields(["x", "y"])
      line = Zone::FieldLine.parse("10,20", delimiter: ",", mapping: mapping)

      line["x"].should eq("10")
      line["y"].should eq("20")
    end
  end

  describe "#transform" do
    it "transforms by index" do
      line = Zone::FieldLine.parse("foo,bar,baz", delimiter: ",")
      result = line.transform(2) { |v| v.upcase }

      result.should be(line)
      # Output delimiter should match input delimiter (comma)
      line.to_s.should eq("foo,BAR,baz")
    end

    it "transforms by name" do
      mapping = Zone::FieldMapping.from_fields(["name", "value"])
      line = Zone::FieldLine.parse("test,100", delimiter: ",", mapping: mapping)

      line.transform("value") { |v| (v.to_i * 2).to_s }

      # Output delimiter should match input delimiter (comma)
      line.to_s.should eq("test,200")
    end
  end

  describe "#transform_all" do
    it "transforms all fields" do
      line = Zone::FieldLine.parse("a,b,c", delimiter: ",")
      line.transform_all(&.upcase)

      # Output delimiter should match input delimiter (comma)
      line.to_s.should eq("A,B,C")
    end
  end

  describe "#to_s" do
    it "reconstructs line with same delimiter" do
      line = Zone::FieldLine.parse("foo,bar,baz", delimiter: ",")

      # Output delimiter should match input delimiter (comma)
      line.to_s.should eq("foo,bar,baz")
    end

    it "handles single field" do
      line = Zone::FieldLine.parse("2025-01-15T10:30:00Z", delimiter: ",")

      line.to_s.should eq("2025-01-15T10:30:00Z")
    end

    it "uses tab for regex delimiter" do
      line = Zone::FieldLine.parse("foo  bar   baz", delimiter: "/\\s+/")

      line.to_s.should match(/\t/)
    end
  end

  describe "#to_a" do
    it "returns fields array" do
      line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

      line.to_a.should eq(["a", "b", "c"])
    end
  end

  describe "#to_h" do
    it "converts to hash with mapping" do
      mapping = Zone::FieldMapping.from_fields(["x", "y", "z"])
      line = Zone::FieldLine.parse("1,2,3", delimiter: ",", mapping: mapping)

      expected = {"x" => "1", "y" => "2", "z" => "3"}
      line.to_h.should eq(expected)
    end

    it "returns empty hash without mapping" do
      line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

      line.to_h.should be_empty
    end
  end

  describe "chainable transformations" do
    it "chains transformations" do
      line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

      result = line
        .transform(1, &.upcase)
        .transform(2, &.upcase)
        .transform(3, &.upcase)

      result.should be(line)
      # Output delimiter should match input delimiter (comma)
      line.to_s.should eq("A,B,C")
    end
  end
end
