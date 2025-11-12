# frozen_string_literal: true

require "test_helper"

class TestFieldMapping < Minitest::Test
  def test_from_fields_creates_mapping
    fields = ["name", "age", "city"]
    mapping = Zone::FieldMapping.from_fields(fields)

    assert_instance_of Zone::FieldMapping, mapping
    assert_equal 0, mapping["name"]
    assert_equal 1, mapping["age"]
    assert_equal 2, mapping["city"]
  end

  def test_numeric_creates_numeric_only_mapping
    mapping = Zone::FieldMapping.numeric

    assert_instance_of Zone::FieldMapping, mapping
    refute mapping.has_names?
    assert_empty mapping.names
  end

  def test_resolve_with_field_name
    mapping = Zone::FieldMapping.from_fields(["name", "timestamp", "value"])

    assert_equal 1, mapping.resolve("timestamp")
  end

  def test_resolve_with_integer_converts_to_zero_based
    mapping = Zone::FieldMapping.numeric

    assert_equal 0, mapping.resolve(1)
    assert_equal 1, mapping.resolve(2)
    assert_equal 9, mapping.resolve(10)
  end

  def test_resolve_with_numeric_string
    mapping = Zone::FieldMapping.numeric

    assert_equal 0, mapping["1"]
    assert_equal 1, mapping["2"]
  end

  def test_bracket_operator_alias
    mapping = Zone::FieldMapping.from_fields(["a", "b", "c"])

    assert_equal 0, mapping["a"]
    assert_equal 1, mapping[2]
  end

  def test_raises_error_for_missing_field_name
    mapping = Zone::FieldMapping.from_fields(["a", "b"])

    error = assert_raises(KeyError) do
      mapping.resolve("nonexistent")
    end

    assert_match(/not found/, error.message)
  end

  def test_raises_error_for_invalid_key_type
    mapping = Zone::FieldMapping.numeric

    assert_raises(ArgumentError) do
      mapping.resolve(3.14)
    end
  end

  def test_names_returns_field_names
    fields = ["foo", "bar", "baz"]
    mapping = Zone::FieldMapping.from_fields(fields)

    assert_equal fields, mapping.names
    assert_includes mapping.names, "foo"
    assert_includes mapping.names, "bar"
  end

  def test_names_empty_for_numeric_mapping
    mapping = Zone::FieldMapping.numeric

    assert_empty mapping.names
  end

  def test_has_names_predicate
    with_names = Zone::FieldMapping.from_fields(["a"])
    numeric = Zone::FieldMapping.numeric

    assert with_names.has_names?
    refute numeric.has_names?
  end
end
