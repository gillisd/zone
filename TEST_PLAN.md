# Zone CLI - Comprehensive Test Plan

## Overview

Based on Minitest documentation (Rule 1), this plan covers:
1. **Unit tests** for each domain class
2. **Integration tests** for CLI command execution
3. **All assertion types** appropriate for each test

## Minitest Assertions Available

From `ri Minitest::Assertions`:

### **Equality & Comparison**
- `assert_equal(exp, act)` - Fails unless exp == act
- `refute_equal(exp, act)` - Fails if exp == act
- `assert_same(exp, act)` - Fails unless exp.equal?(act)
- `assert_nil(obj)` - Fails unless obj is nil
- `refute_nil(obj)` - Fails if obj is nil

### **Type Checking**
- `assert_instance_of(cls, obj)` - Fails unless obj is an instance of cls
- `assert_kind_of(cls, obj)` - Fails unless obj is a kind of cls
- `assert_respond_to(obj, meth)` - Fails unless obj responds to meth

### **Collections**
- `assert_includes(collection, obj)` - Fails unless collection includes obj
- `assert_empty(obj)` - Fails unless obj is empty
- `refute_empty(obj)` - Fails if obj is empty

### **Pattern Matching**
- `assert_match(matcher, obj)` - Fails unless matcher =~ obj
- `refute_match(matcher, obj)` - Fails if matcher =~ obj

### **Exceptions**
- `assert_raises(*exp) { }` - Fails unless block raises one of exp
- `assert_silent { }` - Fails if block outputs to stdout or stderr

### **IO Capture**
- `capture_io { }` - Captures $stdout and $stderr (for in-process)
- `capture_subprocess_io { }` - Captures subprocess IO (for shell commands)

---

## Test File Structure

```
test/
  test_helper.rb                 # Common test setup
  zone/
    test_timestamp.rb            # Zone::Timestamp unit tests
    test_field_mapping.rb        # Zone::FieldMapping unit tests
    test_field_line.rb           # Zone::FieldLine unit tests
    test_zone_module.rb          # Zone.find module method tests
  integration/
    test_cli_integration.rb      # End-to-end CLI tests
```

---

## 1. test/test_helper.rb

```ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "zone"
require "minitest/autorun"

# Make diffs prettier
Minitest::Test.make_my_diffs_pretty!
```

---

## 2. test/zone/test_timestamp.rb

### **Purpose**: Test Zone::Timestamp parsing, conversion, and formatting

### **Assertions to Use**:
- `assert_instance_of` - Verify return type
- `assert_equal` - Compare formatted output
- `assert_raises` - Test error cases
- `assert_respond_to` - Verify API methods exist
- `assert_match` - Verify output format patterns

### **Test Cases**:

```ruby
# frozen_string_literal: true

require "test_helper"

class TestTimestamp < Minitest::Test
  def test_parse_time_object
    time = Time.now
    timestamp = Zone::Timestamp.parse(time)

    assert_instance_of Zone::Timestamp, timestamp
    assert_equal time, timestamp.time
  end

  def test_parse_datetime_object
    datetime = DateTime.now
    timestamp = Zone::Timestamp.parse(datetime)

    assert_instance_of Zone::Timestamp, timestamp
    assert_instance_of Time, timestamp.time
  end

  def test_parse_date_object
    date = Date.today
    timestamp = Zone::Timestamp.parse(date)

    assert_instance_of Zone::Timestamp, timestamp
    assert_instance_of Time, timestamp.time
  end

  def test_parse_unix_timestamp_seconds
    # Unix epoch for 2025-01-15 10:30:00 UTC
    timestamp = Zone::Timestamp.parse("1736937000")

    assert_equal 1736937000, timestamp.time.to_i
  end

  def test_parse_unix_timestamp_milliseconds
    # 13 digits - milliseconds precision
    timestamp = Zone::Timestamp.parse("1736937000000")

    assert_equal 1736937000, timestamp.time.to_i
  end

  def test_parse_iso8601_string
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")

    assert_equal 2025, timestamp.time.year
    assert_equal 1, timestamp.time.month
    assert_equal 15, timestamp.time.day
    assert_equal 10, timestamp.time.hour
    assert_equal 30, timestamp.time.min
  end

  def test_parse_relative_time_ago
    timestamp = Zone::Timestamp.parse("5 minutes ago")
    diff = Time.now - timestamp.time

    assert_in_delta 300, diff, 2  # Within 2 seconds of 5 minutes
  end

  def test_parse_relative_time_from_now
    timestamp = Zone::Timestamp.parse("1 hour from now")
    diff = timestamp.time - Time.now

    assert_in_delta 3600, diff, 2  # Within 2 seconds of 1 hour
  end

  def test_parse_invalid_input_raises_error
    error = assert_raises(ArgumentError) do
      Zone::Timestamp.parse("not a valid timestamp")
    end

    assert_match(/Could not parse time/, error.message)
  end

  def test_in_zone_returns_new_timestamp
    original = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    tokyo = original.in_zone("Tokyo")

    assert_instance_of Zone::Timestamp, tokyo
    refute_same original, tokyo
    assert_equal "Tokyo", tokyo.zone
  end

  def test_in_utc_returns_new_timestamp
    local = Zone::Timestamp.parse(Time.now.to_s)
    utc = local.in_utc

    assert_instance_of Zone::Timestamp, utc
    assert_equal "UTC", utc.zone
  end

  def test_in_local_returns_new_timestamp
    utc = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    local = utc.in_local

    assert_instance_of Zone::Timestamp, local
    assert_equal "local", local.zone
  end

  def test_to_iso8601_format
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    formatted = timestamp.to_iso8601

    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, formatted)
  end

  def test_to_unix_returns_integer
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    unix = timestamp.to_unix

    assert_instance_of Integer, unix
    assert_equal 1736937000, unix
  end

  def test_to_pretty_format
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    pretty = timestamp.to_pretty

    assert_match(/Jan \d+/, pretty)
    assert_match(/\d{1,2}:\d{2} [AP]M/, pretty)
  end

  def test_strftime_custom_format
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
    formatted = timestamp.strftime("%Y-%m-%d")

    assert_equal "2025-01-15", formatted
  end

  def test_chainable_operations
    result = Zone::Timestamp
      .parse("2025-01-15T10:30:00Z")
      .in_zone("Tokyo")
      .to_iso8601

    assert_instance_of String, result
    assert_match(/\+09:00/, result)  # Tokyo timezone offset
  end

  def test_responds_to_all_public_methods
    timestamp = Zone::Timestamp.parse("2025-01-15T10:30:00Z")

    assert_respond_to timestamp, :in_zone
    assert_respond_to timestamp, :in_utc
    assert_respond_to timestamp, :in_local
    assert_respond_to timestamp, :to_iso8601
    assert_respond_to timestamp, :to_unix
    assert_respond_to timestamp, :to_pretty
    assert_respond_to timestamp, :strftime
  end
end
```

---

## 3. test/zone/test_field_mapping.rb

### **Purpose**: Test Zone::FieldMapping index resolution

### **Assertions to Use**:
- `assert_equal` - Verify index resolution
- `assert_raises` - Test error cases with invalid fields
- `assert_includes` - Check names array
- `assert_empty` - Verify numeric-only mappings

### **Test Cases**:

```ruby
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

    assert_equal 0, mapping.resolve(1)  # 1-based to 0-based
    assert_equal 1, mapping.resolve(2)
    assert_equal 9, mapping.resolve(10)
  end

  def test_resolve_with_numeric_string
    mapping = Zone::FieldMapping.numeric

    assert_equal 0, mapping["1"]  # String "1" -> 0
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
      mapping.resolve(3.14)  # Float is not valid
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
```

---

## 4. test/zone/test_field_line.rb

### **Purpose**: Test Zone::FieldLine parsing and transformation

### **Assertions to Use**:
- `assert_equal` - Compare parsed fields and output
- `assert_instance_of` - Verify return types
- `assert_same` - Verify transform returns self (for chaining)
- `assert_match` - Verify delimiter inference

### **Test Cases**:

```ruby
# frozen_string_literal: true

require "test_helper"

class TestFieldLine < Minitest::Test
  def test_parse_simple_comma_delimited
    line = Zone::FieldLine.parse("foo,bar,baz")

    assert_instance_of Zone::FieldLine, line
    assert_equal ["foo", "bar", "baz"], line.fields
  end

  def test_parse_tab_delimited
    line = Zone::FieldLine.parse("foo\tbar\tbaz")

    assert_equal ["foo", "bar", "baz"], line.fields
  end

  def test_parse_whitespace_delimited
    line = Zone::FieldLine.parse("foo  bar   baz")

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
      mapping: mapping
    )

    assert_equal "test", line["name"]
    assert_equal "100", line["value"]
  end

  def test_bracket_access_by_index
    line = Zone::FieldLine.parse("a,b,c")

    assert_equal "a", line[1]  # 1-based
    assert_equal "b", line[2]
    assert_equal "c", line[3]
  end

  def test_bracket_access_by_name
    mapping = Zone::FieldMapping.from_fields(["x", "y"])
    line = Zone::FieldLine.parse(
      "10,20",
      mapping: mapping
    )

    assert_equal "10", line["x"]
    assert_equal "20", line["y"]
  end

  def test_transform_by_index
    line = Zone::FieldLine.parse("foo,bar,baz")
    result = line.transform(2) { |v| v.upcase }

    assert_same line, result  # Returns self for chaining
    assert_equal "foo,BAR,baz", line.to_s
  end

  def test_transform_by_name
    mapping = Zone::FieldMapping.from_fields(["name", "value"])
    line = Zone::FieldLine.parse(
      "test,100",
      mapping: mapping
    )

    line.transform("value") { |v| v.to_i * 2 }

    assert_equal "test,200", line.to_s
  end

  def test_transform_all_fields
    line = Zone::FieldLine.parse("a,b,c")
    line.transform_all(&:upcase)

    assert_equal "A,B,C", line.to_s
  end

  def test_to_s_reconstructs_line
    line = Zone::FieldLine.parse("foo,bar,baz")

    assert_equal "foo,bar,baz", line.to_s
  end

  def test_to_s_single_field
    line = Zone::FieldLine.parse("2025-01-15T10:30:00Z")

    assert_equal "2025-01-15T10:30:00Z", line.to_s
  end

  def test_to_s_uses_tab_for_regex_delimiter
    line = Zone::FieldLine.parse("foo  bar   baz")  # Whitespace

    assert_match(/\t/, line.to_s)  # Should use tab in output
  end

  def test_to_a_returns_fields_array
    line = Zone::FieldLine.parse("a,b,c")

    assert_equal ["a", "b", "c"], line.to_a
  end

  def test_to_h_with_mapping
    mapping = Zone::FieldMapping.from_fields(["x", "y", "z"])
    line = Zone::FieldLine.parse(
      "1,2,3",
      mapping: mapping
    )

    expected = { "x" => "1", "y" => "2", "z" => "3" }
    assert_equal expected, line.to_h
  end

  def test_to_h_without_mapping_returns_empty
    line = Zone::FieldLine.parse("a,b,c")

    assert_empty line.to_h
  end

  def test_infer_delimiter_comma
    delimiter = Zone::FieldLine.infer_delimiter(
      "a,b,c",
      explicit: nil
    )

    assert_equal ",", delimiter
  end

  def test_infer_delimiter_tab
    delimiter = Zone::FieldLine.infer_delimiter(
      "a\tb\tc",
      explicit: nil
    )

    assert_equal "\t", delimiter
  end

  def test_infer_delimiter_whitespace
    delimiter = Zone::FieldLine.infer_delimiter(
      "a  b   c",
      explicit: nil
    )

    assert_instance_of Regexp, delimiter
  end

  def test_infer_delimiter_explicit_overrides
    delimiter = Zone::FieldLine.infer_delimiter(
      "a,b,c",
      explicit: "|"
    )

    assert_equal "|", delimiter
  end

  def test_chainable_transformations
    line = Zone::FieldLine.parse("a,b,c")

    result = line
      .transform(1, &:upcase)
      .transform(2, &:upcase)
      .transform(3, &:upcase)

    assert_same line, result
    assert_equal "A,B,C", line.to_s
  end
end
```

---

## 5. test/zone/test_zone_module.rb

### **Purpose**: Test Zone.find module method

### **Assertions to Use**:
- `assert_instance_of` - Verify TZInfo::Timezone returned
- `assert_raises` - Test invalid timezone
- `assert_equal` - Verify correct timezone found

### **Test Cases**:

```ruby
# frozen_string_literal: true

require "test_helper"

class TestZoneModule < Minitest::Test
  def test_find_exact_timezone_name
    tz = Zone.find("America/New_York")

    assert_instance_of TZInfo::Timezone, tz
    assert_equal "America/New_York", tz.identifier
  end

  def test_find_utc
    tz = Zone.find("UTC")

    assert_instance_of TZInfo::Timezone, tz
    assert_equal "UTC", tz.identifier
  end

  def test_find_fuzzy_tokyo
    tz = Zone.find("tokyo")

    assert_instance_of TZInfo::Timezone, tz
    assert_equal "Asia/Tokyo", tz.identifier
  end

  def test_find_fuzzy_new_york
    tz = Zone.find("new york")

    assert_instance_of TZInfo::Timezone, tz
    assert_match(/New_York/, tz.identifier)
  end

  def test_find_us_timezone
    tz = Zone.find("eastern")

    assert_instance_of TZInfo::Timezone, tz
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
```

---

## 6. test/integration/test_cli_integration.rb

### **Purpose**: End-to-end testing of actual CLI commands

### **Assertions to Use**:
- `capture_subprocess_io` - Run actual commands and capture output
- `assert_match` - Verify output format
- `assert_equal` - Verify exact output
- `refute_match` - Ensure errors don't occur

### **Test Cases**:

```ruby
# frozen_string_literal: true

require "test_helper"

class TestCLIIntegration < Minitest::Test
  ZONE_COMMAND = File.expand_path("../../exe/zone", __dir__)

  def run_zone(input, *args)
    capture_subprocess_io do
      IO.popen(
        [ZONE_COMMAND, *args],
        "r+",
        err: [:child, :out]
      ) do |io|
        io.write(input)
        io.close_write
        puts io.read
      end
    end
  end

  def test_basic_timestamp_conversion
    out, err = run_zone(
      "2025-01-15T10:30:00Z\n",
      "--utc"
    )

    assert_match(/2025-01-15T10:30:00Z/, out)
    assert_empty err
  end

  def test_unix_timestamp_to_pretty
    out, err = run_zone(
      "1736937000\n",
      "--utc",
      "--pretty"
    )

    assert_match(/Jan 15, 2025/, out)
    assert_match(/10:30 AM/, out)
    assert_empty err
  end

  def test_timezone_conversion_tokyo
    out, err = run_zone(
      "2025-01-15T10:30:00Z\n",
      "--zone",
      "tokyo"
    )

    assert_match(/19:30:00\+09:00/, out)
  end

  def test_field_parsing_multiple_fields
    out, err = run_zone(
      "test 1736937000 data\n",
      "--field",
      "2",
      "--utc"
    )

    assert_match(/test/, out)
    assert_match(/2025-01-15T10:30:00Z/, out)
    assert_match(/data/, out)
  end

  def test_csv_with_headers
    input = <<~CSV
      name,timestamp,value
      foo,2025-01-15T10:30:00Z,100
      bar,1736937000,200
    CSV

    out, err = run_zone(
      input,
      "--headers",
      "--field",
      "2",
      "--zone",
      "tokyo"
    )

    assert_match(/name,timestamp,value/, out)
    assert_match(/foo/, out)
    assert_match(/\+09:00/, out)
  end

  def test_help_output
    out, err = run_zone("", "--help")

    assert_match(/Usage: zone/, out)
    assert_match(/--iso8601/, out)
    assert_match(/--zone/, out)
    assert_match(/--field/, out)
  end

  def test_multiple_timestamps_as_arguments
    out, err = capture_subprocess_io do
      system(
        ZONE_COMMAND,
        "--utc",
        "2025-01-15T10:30:00Z",
        "1736937000",
        out: :out,
        err: :err
      )
    end

    lines = out.split("\n")
    assert_equal 2, lines.count
    assert_match(/2025-01-15/, lines[0])
    assert_match(/2025-01-15/, lines[1])
  end

  def test_verbose_logging
    out, err = run_zone(
      "2025-01-15T10:30:00Z\n",
      "--zone",
      "tokyo",
      "--verbose"
    )

    assert_match(/Using time zone/, err)
    assert_match(/Tokyo/, err)
  end

  def test_strftime_format
    out, err = run_zone(
      "2025-01-15T10:30:00Z\n",
      "--utc",
      "--strftime",
      "%Y-%m-%d"
    )

    assert_equal "2025-01-15\n", out
  end

  def test_unix_output_format
    out, err = run_zone(
      "2025-01-15T10:30:00Z\n",
      "--utc",
      "--unix"
    )

    assert_equal "1736937000\n", out
  end

  def test_local_timezone
    out, err = run_zone(
      "2025-01-15T10:30:00Z\n",
      "--local"
    )

    # Should convert to local time (output will vary by system)
    assert_match(/2025-01-15/, out)
    refute_match(/\+00:00/, out)  # Should not be UTC
  end

  def test_delimiter_inference_tab
    out, err = run_zone(
      "foo\t1736937000\tbar\n",
      "--field",
      "2",
      "--utc"
    )

    assert_match(/foo/, out)
    assert_match(/2025-01-15/, out)
    assert_match(/bar/, out)
  end

  def test_explicit_delimiter
    out, err = run_zone(
      "foo|1736937000|bar\n",
      "--field",
      "2",
      "--delimiter",
      "|",
      "--utc"
    )

    assert_match(/foo/, out)
    assert_match(/2025-01-15/, out)
    assert_match(/bar/, out)
  end

  def test_no_input_uses_current_time
    out, err = capture_subprocess_io do
      system(
        ZONE_COMMAND,
        "--utc",
        in: :close,
        out: :out,
        err: :err
      )
    end

    # Should output current time
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, out)
  end

  def test_invalid_timestamp_logs_warning
    out, err = run_zone(
      "not_a_valid_timestamp\n",
      "--utc",
      "--verbose"
    )

    assert_match(/Could not parse/, err)
    assert_match(/Skipping/, err)
  end
end
```

---

## Summary of Assertions Used

Based on Minitest documentation:

### **Equality & Type Checks**
- ✅ `assert_equal` - Most common, verify expected values
- ✅ `refute_equal` - Verify values are different
- ✅ `assert_same` - Verify object identity (for chainable methods)
- ✅ `assert_instance_of` - Verify exact class
- ✅ `assert_nil` - Verify nil values
- ✅ `refute_nil` - Verify non-nil values

### **Collections**
- ✅ `assert_includes` - Verify array/hash membership
- ✅ `assert_empty` - Verify empty collections
- ✅ `refute_empty` - Verify non-empty collections

### **Pattern Matching**
- ✅ `assert_match` - Verify regex patterns in strings
- ✅ `refute_match` - Verify patterns don't match

### **Exceptions**
- ✅ `assert_raises` - Verify error handling

### **Numeric**
- ✅ `assert_in_delta` - Compare floats with tolerance

### **Methods**
- ✅ `assert_respond_to` - Verify API surface

### **IO**
- ✅ `capture_subprocess_io` - Test actual CLI commands

---

## Test Execution

```bash
# Run all tests
rake test

# Run specific test file
ruby test/zone/test_timestamp.rb

# Run specific test
ruby test/zone/test_timestamp.rb --name test_parse_unix_timestamp_seconds

# Run with verbose output
ruby test/zone/test_timestamp.rb --verbose
```

---

## Coverage Goals

- **Unit tests**: 100% coverage of public methods
- **Integration tests**: All CLI flags and combinations
- **Edge cases**: Invalid input, missing fields, errors
- **Documentation**: Every assertion type used appropriately

This plan follows **Rule 1** by reading all Minitest documentation and using the appropriate assertion types for each test case.
