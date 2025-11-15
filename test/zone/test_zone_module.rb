# frozen_string_literal: true

require "test_helper"

class TestZoneModule < Minitest::Test
  parallelize_me!

  def test_find_exact_timezone_name
    tz = Zone.find("America/New_York")

    assert_kind_of TZInfo::Timezone, tz
    assert_equal "America/New_York", tz.identifier
  end

  def test_find_utc
    tz = Zone.find("UTC")

    assert_kind_of TZInfo::Timezone, tz
    assert_equal "UTC", tz.identifier
  end

  def test_find_fuzzy_tokyo
    tz = Zone.find("tokyo")

    assert_kind_of TZInfo::Timezone, tz
    assert_equal "Asia/Tokyo", tz.identifier
  end

  def test_find_fuzzy_new_york
    tz = Zone.find("new york")

    assert_kind_of TZInfo::Timezone, tz
    assert_match(/New_York/, tz.identifier)
  end

  def test_find_us_timezone
    skip "TZInfo data varies by environment - US/Eastern may not exist"
    tz = Zone.find("eastern")

    assert_kind_of TZInfo::Timezone, tz
    assert_match(/^US\//, tz.identifier)
  end

  def test_find_returns_nil_for_invalid
    tz = Zone.find("not_a_real_timezone_12345")

    assert_nil tz
  end

  def test_find_case_insensitive
    tz1 = Zone.find("Tokyo")
    tz2 = Zone.find("TOKYO")
    tz3 = Zone.find("tokyo")

    assert_equal tz1.identifier, tz2.identifier
    assert_equal tz2.identifier, tz3.identifier
  end
end
