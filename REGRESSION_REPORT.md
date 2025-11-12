# Regression Report: Field Processing Behavior

**Date**: November 12, 2025
**Branches Compared**: `advanced-parsing` (original) vs `advanced-parsing-auto` (refactored)
**Severity**: CRITICAL - Core functionality broken

---

## Executive Summary

The refactored implementation (`advanced-parsing-auto`) introduces a **critical regression** in field processing behavior:

- **Original behavior**: Transforms specified field and outputs the **full line** with other fields preserved
- **Refactored behavior**: Outputs **only the transformed field**, losing all other data

**Test Results**:
- Original branch: **18/22 tests pass** (82%)
- Refactored branch: **1/22 tests pass** (5%)

This regression makes the tool unusable for its primary use cases: log processing and structured data transformation.

---

## The Core Issue

### What Should Happen

```bash
$ echo "Thomas,1901-01-01+19:07Z" | exe/zone -z Tokyo --field 2
Thomas	1901-01-02T04:07:00+09:00
```

The output preserves "Thomas" and includes the transformed timestamp.

### What Actually Happens (My Refactor)

```bash
$ echo "Thomas,1901-01-01+19:07Z" | exe/zone -z Tokyo --field 2
1901-01-02T04:07:00+09:00
```

The output loses "Thomas" entirely.

---

## Root Cause Analysis

### Original Implementation (`advanced-parsing`)

Located in `exe/zone`, lines 220-234:

```ruby
class FieldMap
  def update!(line, field)
    line_delimiter = infer_delimiter(line)

    split = split_line(line, line_delimiter)
    field = @mapping[field]
    value = split[field]&.strip

    new_value = yield value          # Transform the field value
    split[field] = new_value         # Replace it in the array

    output_delim = (line_delimiter in Regexp) ? "\t" : line_delimiter
    if field == 1 && split.count == 1
      return split                   # Edge case: single field
    end
    split.join(output_delim)         # JOIN BACK TO FULL LINE
  end
end
```

**Key insight**: The `update!` method returns the **full line** with the field replaced.

### Refactored Implementation (`advanced-parsing-auto`)

Located in `lib/zone/cli.rb`, lines 250-268:

```ruby
def process_lines(transformation, mapping)
  input = build_input_source
  use_field_processing = needs_field_processing?

  input.each do |line_text|
    if use_field_processing
      field_line = FieldLine.parse(...)

      field_line.transform(@options[:field], &transformation)

      # Output only the transformed field
      transformed_value = field_line[@options[:field]]
      $stdout.puts transformed_value unless transformed_value.nil?
    else
      # ...
    end
  end
end
```

**Problem**: Line 261 outputs `transformed_value` (just the field), not the full line.

The `FieldLine` class has a `transform` method that correctly replaces the field in the internal array, but `process_lines` never calls a method to get the full transformed line.

---

## Failed Test Cases

### Category 1: Basic Line Preservation (8 failures)

```ruby
# Test: Field 2 with spaces
Input:  "user1 2025-01-15T10:30:00Z active"
Expected: "user1\t1736937000\tactive"
Actual:   "1736937000"

# Test: CSV with comma delimiter
Input:  "Thomas,1901-01-01+19:07Z"
Expected: "Thomas\t1901-01-02T04:07:00+09:00"
Actual:   "1901-01-02T04:07:00+09:00"

# Test: Multiple lines
Input:  "user1 1736937000 active\nuser2 1736940600 inactive"
Expected: Both lines with all fields preserved
Actual:   Only timestamps, no user names or status
```

### Category 2: Headers (2 failures)

```ruby
# Test: Headers with named field
Input:  "user,timestamp,status\nalice,1736937000,active"
Expected: 2 lines (header + data, both with all fields)
Actual:   1 line (only the timestamp, header lost)
```

### Category 3: Real-World Workflows (2 failures)

```ruby
# Test: CSV processing workflow
Input:  "name,login_time,status\nalice,1736937000,active\nbob,1736940600,inactive"
Expected: 3 lines with all fields preserved
Actual:   2 lines with only timestamps

# Test: Log processing
Input:  "[INFO] 1736937000 User logged in"
Expected: "[INFO]\tJan 15, 2025 - 10:30 AM UTC\tUser\tlogged\tin"
Actual:   "Jan 15, 2025 - 10:30 AM UTC"
```

### Category 4: Edge Cases (8 failures)

All tests involving multiple fields fail because only the transformed field is output.

---

## User Impact

### Broken Use Cases

1. **Log Processing**: Cannot transform timestamps in logs while preserving log messages
   ```bash
   # BROKEN:
   tail -f app.log | zone --field 2 --pretty --zone local
   ```

2. **CSV Transformation**: Cannot convert timestamp columns while keeping other columns
   ```bash
   # BROKEN:
   cat users.csv | zone --headers --field login_time --zone Tokyo
   ```

3. **Data Pipeline**: Cannot use zone in middle of pipeline that needs full records
   ```bash
   # BROKEN:
   cat data.tsv | zone --field 3 --unix | awk '{print $1, $4}'
   ```

### What Still Works

- Single timestamp conversion: `zone "2025-01-15T10:30:00Z" --pretty`
- Piped single timestamps: `date | zone --zone Tokyo`
- Field 1 with single field: `echo "2025-01-15T10:30:00Z" | zone --field 1 --unix`

---

## Test Suite Coverage

### Created: `test/integration/test_10_10_behavior.rb`

**Purpose**: Define expected behavior based on original implementation

**Coverage**:
- Core line preservation (8 tests)
- Edge cases for single field (2 tests)
- Delimiter handling (3 tests)
- Real-world workflows (3 tests)
- Field indexing (2 tests)
- Error handling (2 tests)
- Format combinations (2 tests)

**Total**: 22 comprehensive integration tests

### Results by Branch

| Branch | Passing | Failing | Pass Rate |
|--------|---------|---------|-----------|
| `advanced-parsing` (original) | 18 | 4 | 82% |
| `advanced-parsing-auto` (refactored) | 1 | 21 | 5% |

### Failures in Original Implementation

The original code has 4 test failures revealing bugs:

1. **Explicit delimiter not respected**: `--delimiter "|"` is ignored, auto-detection used instead
2. **Tab delimiter removed**: Tab-delimited files lose tabs in output (joins without delimiter)
3. **Log messages split incorrectly**: Each word treated as separate field
4. **TSV output concatenated**: Tab-separated values output without separators

These are bugs in the original but don't affect the core line-preservation behavior.

---

## What the Refactor Got Right

Despite the regression, the refactored code has strengths:

1. **Clean architecture**: `Timestamp`, `FieldLine`, `FieldMapping` are well-designed domain objects
2. **Better error handling**: Improved error messages with color highlighting
3. **Proper separation**: CLI logic separated from domain logic
4. **Test coverage**: 88 unit tests for individual components
5. **Code quality**: Eliminates "-er" classes, uses Ruby idioms properly

**The problem**: Architecture refactor was done without preserving behavior.

---

## Required Fix

### The Fix in `lib/zone/cli.rb`

Change line 261 from:
```ruby
transformed_value = field_line[@options[:field]]
$stdout.puts transformed_value unless transformed_value.nil?
```

To:
```ruby
full_line = field_line.to_s  # or field_line.join(delimiter)
$stdout.puts full_line
```

### Required Addition to `FieldLine` class

Add method to output the full line:
```ruby
def to_s
  @fields.join(@delimiter)
end
```

Or similar method that reconstructs the line with the transformed field in place.

---

## Lessons Learned

1. **Understand before refactoring**: Should have documented original behavior first
2. **Test behavior, not implementation**: Unit tests verified the new design but not the original behavior
3. **Regression testing is essential**: Should have run identical commands on both branches
4. **Integration tests first**: Should write integration tests capturing current behavior before refactoring
5. **User feedback is critical**: The `date | zone` bug masked the real issue

---

## Recommendation

**DO NOT MERGE** `advanced-parsing-auto` until the regression is fixed.

**Priority**: P0 - Critical functionality broken

**Estimated Fix Time**: 2-4 hours
- Add `to_s` / `join` method to `FieldLine`
- Update `process_lines` to output full line
- Verify all 18 passing tests from original still pass
- Fix the 4 bugs in original implementation if possible

**Definition of Done**:
- All 22 integration tests pass (or documented reasons for expected failures)
- Manual verification: `echo "Thomas,1901-01-01+19:07Z" | exe/zone -z Tokyo --field 2` outputs full line
- No regressions in existing test suite
