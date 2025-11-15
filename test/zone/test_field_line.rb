# frozen_string_literal: true

require "test_helper"

class TestFieldLine < Minitest::Test
  parallelize_me!

  def test_parse_simple_comma_delimited
    line = Zone::FieldLine.parse("foo,bar,baz", delimiter: ",")

    assert_instance_of Zone::FieldLine, line
    assert_equal ["foo", "bar", "baz"], line.fields
  end

  def test_parse_tab_delimited
    line = Zone::FieldLine.parse("foo\tbar\tbaz", delimiter: "\t")

    assert_equal ["foo", "bar", "baz"], line.fields
  end

  def test_parse_whitespace_delimited
    line = Zone::FieldLine.parse("foo  bar   baz", delimiter: "/\\s+/")

    assert_equal ["foo", "bar", "baz"], line.fields
  end

  def test_parse_with_explicit_delimiter
    line = Zone::FieldLine.parse(
      "foo|bar|baz",
      delimiter: "|"
    )

    assert_equal ["foo", "bar", "baz"], line.fields
  end

  def test_parse_with_mapping
    mapping = Zone::FieldMapping.from_fields(["name", "value"])
    line = Zone::FieldLine.parse(
      "test,100",
      delimiter: ",",
      mapping: mapping
    )

    assert_equal "test", line["name"]
    assert_equal "100", line["value"]
  end

  def test_bracket_access_by_index
    line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

    assert_equal "a", line[1]
    assert_equal "b", line[2]
    assert_equal "c", line[3]
  end

  def test_bracket_access_by_name
    mapping = Zone::FieldMapping.from_fields(["x", "y"])
    line = Zone::FieldLine.parse(
      "10,20",
      delimiter: ",",
      mapping: mapping
    )

    assert_equal "10", line["x"]
    assert_equal "20", line["y"]
  end

  def test_transform_by_index
    line = Zone::FieldLine.parse("foo,bar,baz", delimiter: ",")
    result = line.transform(2) { |v| v.upcase }

    assert_same line, result
    assert_equal "foo\tBAR\tbaz", line.to_s
  end

  def test_transform_by_name
    mapping = Zone::FieldMapping.from_fields(["name", "value"])
    line = Zone::FieldLine.parse(
      "test,100",
      delimiter: ",",
      mapping: mapping
    )

    line.transform("value") { |v| (v.to_i * 2).to_s }

    assert_equal "test\t200", line.to_s
  end

  def test_transform_all_fields
    line = Zone::FieldLine.parse("a,b,c", delimiter: ",")
    line.transform_all(&:upcase)

    assert_equal "A\tB\tC", line.to_s
  end

  def test_to_s_reconstructs_line
    line = Zone::FieldLine.parse("foo,bar,baz", delimiter: ",")

    assert_equal "foo\tbar\tbaz", line.to_s
  end

  def test_to_s_single_field
    line = Zone::FieldLine.parse("2025-01-15T10:30:00Z", delimiter: ",")

    assert_equal "2025-01-15T10:30:00Z", line.to_s
  end

  def test_to_s_uses_tab_for_regex_delimiter
    line = Zone::FieldLine.parse("foo  bar   baz", delimiter: "/\\s+/")

    assert_match(/\t/, line.to_s)
  end

  def test_to_a_returns_fields_array
    line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

    assert_equal ["a", "b", "c"], line.to_a
  end

  def test_to_h_with_mapping
    mapping = Zone::FieldMapping.from_fields(["x", "y", "z"])
    line = Zone::FieldLine.parse(
      "1,2,3",
      delimiter: ",",
      mapping: mapping
    )

    expected = { "x" => "1", "y" => "2", "z" => "3" }
    assert_equal expected, line.to_h
  end

  def test_to_h_without_mapping_returns_empty
    line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

    assert_empty line.to_h
  end

  def test_chainable_transformations
    line = Zone::FieldLine.parse("a,b,c", delimiter: ",")

    result = line
      .transform(1, &:upcase)
      .transform(2, &:upcase)
      .transform(3, &:upcase)

    assert_same line, result
    assert_equal "A\tB\tC", line.to_s
  end
end
