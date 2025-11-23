# Zone Refactoring Plan

## Overview

This document outlines a comprehensive refactoring plan for the Zone project, based on principles from Martin Fowler's "Refactoring: Improving the Design of Existing Code". The goal is to improve code maintainability, reduce duplication, and enhance architectural clarity while maintaining 100% test coverage and zero regressions.

## Guiding Principles

1. **Make it work, make it right, make it fast** - Refactor for clarity first, optimize later
2. **Small steps with tests** - Each refactoring must maintain green tests
3. **One refactoring at a time** - Never mix feature work with refactoring
4. **Commit frequently** - Each successful refactoring gets its own commit
5. **Code should be self-documenting** - Reduce comments through better naming

---

## Current Code Smells Identified

### 1. Long Method - `parse_string` in timestamp.cr (lines 20-52)
**Severity**: Medium
**Location**: `src/zone/timestamp.cr:20-52`

The `parse_string` method attempts multiple parsing strategies in sequence. While functional, it's doing too much.

**Symptoms**:
- 30+ lines of sequential pattern matching
- Multiple concerns (pattern detection, parsing, error handling)
- Difficult to add new timestamp formats

### 2. Shotgun Surgery - Adding New Timestamp Patterns
**Severity**: High
**Location**: `src/zone/timestamp_patterns.cr` and `src/zone/timestamp.cr`

Adding a new timestamp format requires changes in multiple places:
- Define pattern constant in `timestamp_patterns.cr`
- Add to `patterns` array
- Add to `pattern_name_from_constant` case statement
- Add parsing logic in `timestamp.cr`

**Impact**: High friction for extending functionality

### 3. Feature Envy - `process_line` in field.cr
**Severity**: Low
**Location**: `src/zone/field.cr:19-69`

The `process_line` method does extensive manipulation of `FieldLine` and `Options` objects, suggesting responsibilities might be misplaced.

### 4. Primitive Obsession - Regex matching in `parse_string`
**Severity**: Medium
**Location**: `src/zone/timestamp.cr:20-52`

Heavy use of inline regex patterns and match data extraction. Could benefit from domain objects.

### 5. Duplicated Code - Pattern matching in tests
**Severity**: Low
**Location**: `spec/integration/cli_integration_spec.cr`

Test helper methods could be extracted to reduce duplication in integration tests.

---

## Proposed Refactorings

### Phase 1: Extract Pattern Strategy (High Priority)

**Refactoring**: Replace Type Code with Strategy Pattern
**Effort**: High (3-5 hours)
**Risk**: Medium
**Benefit**: High - Eliminates shotgun surgery smell

#### Goal
Make timestamp patterns self-contained, with each pattern knowing how to match and parse.

#### Proposed Design

```crystal
module Zone
  abstract class TimestampPattern
    abstract def pattern : Regex
    abstract def parse(input : String) : Time?
    abstract def name : String

    def matches?(input : String) : Bool
      !pattern.match(input).nil?
    end
  end

  class ISO8601WithTzPattern < TimestampPattern
    def pattern : Regex
      /\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?[+-]\d{2}:\d{2}\b/
    end

    def parse(input : String) : Time?
      Time.parse_rfc3339(input) rescue nil
    end

    def name : String
      "ISO8601_WITH_TZ"
    end
  end

  # ... similar for each pattern
end
```

#### Benefits
- Adding new patterns requires only one new class
- Each pattern is self-contained and testable
- Eliminates the giant case statement in `pattern_name_from_constant`
- Parser logic lives with pattern definition

#### Migration Strategy
1. Create base `TimestampPattern` abstract class
2. Extract one pattern (e.g., ISO8601) to new class - verify tests pass
3. Migrate remaining patterns one at a time
4. Update `TimestampPatterns` module to return array of pattern instances
5. Simplify `parse_string` to iterate over pattern objects
6. Remove old constants and case statements

#### Tests Required
- Each pattern class should have unit tests
- Integration tests should remain unchanged
- Add tests for pattern priority ordering

---

### Phase 2: Extract TimestampParser Class (Medium Priority)

**Refactoring**: Extract Class
**Effort**: Medium (2-3 hours)
**Risk**: Low
**Benefit**: Medium - Better separation of concerns

#### Goal
Separate parsing logic from Timestamp value object.

#### Current Structure
```crystal
class Timestamp
  # Parsing logic
  def self.parse(input : String | Time) : Timestamp
  private def self.parse_string(input : String) : Time
  private def self.parse_unix(str : String) : Time
  # ... more parsing methods

  # Value object behavior
  def in_zone(zone_name : String) : Timestamp
  def to_iso8601 : String
  # ... more conversion methods
end
```

#### Proposed Structure
```crystal
class TimestampParser
  def self.parse(input : String) : Time
    patterns.each do |pattern|
      if time = pattern.parse(input)
        return time
      end
    end
    raise ArgumentError.new("Could not parse time '#{input}'")
  end

  private def self.patterns : Array(TimestampPattern)
    # Returns ordered array of pattern instances
  end
end

class Timestamp
  def self.parse(input : String | Time) : Timestamp
    time = input.is_a?(Time) ? input : TimestampParser.parse(input)
    new(time)
  end

  # Value object methods only
  def in_zone(zone_name : String) : Timestamp
  def to_iso8601 : String
  # ...
end
```

#### Benefits
- Single Responsibility Principle - Timestamp focuses on conversion/formatting
- TimestampParser focuses solely on parsing
- Easier to test parsing in isolation
- Clearer API boundaries

#### Migration Strategy
1. Create `TimestampParser` class
2. Move `parse_string` and helper methods to `TimestampParser`
3. Update `Timestamp.parse` to delegate to `TimestampParser`
4. Run full test suite
5. Commit

---

### Phase 3: Introduce Parameter Object for TimeComponents (Low Priority)

**Refactoring**: Introduce Parameter Object
**Effort**: Low (1-2 hours)
**Risk**: Low
**Benefit**: Low - Cleaner method signatures

#### Goal
Reduce parameter passing in parsing methods.

#### Current
```crystal
private def self.parse_12hour_with_zone(match_data : Regex::MatchData) : Time
  hour_24 = convert_to_24hour(match_data["hour"].to_i, match_data["ampm"])
  location = load_timezone(match_data["zone"])
  time_str = "#{match_data["date"]} #{hour_24.to_s.rjust(2, '0')}:#{match_data["min"]}:#{match_data["sec"]}"
  Time.parse(time_str, "%Y-%m-%d %H:%M:%S", location)
end
```

#### Proposed
```crystal
struct TimeComponents
  property date : String
  property hour : Int32
  property minute : String
  property second : String
  property meridiem : String?
  property timezone : String?

  def to_24hour : Int32
    return hour unless meridiem

    case meridiem
    when "PM"
      hour == 12 ? 12 : hour + 12
    when "AM"
      hour == 12 ? 0 : hour
    else
      hour
    end
  end

  def to_time_string : String
    "#{date} #{to_24hour.to_s.rjust(2, '0')}:#{minute}:#{second}"
  end
end

private def self.parse_12hour_with_zone(components : TimeComponents) : Time
  location = load_timezone(components.timezone)
  Time.parse(components.to_time_string, "%Y-%m-%d %H:%M:%S", location)
end
```

#### Benefits
- Encapsulates time component logic
- Reduces method parameter count
- Makes time component validation easier
- Business logic (12-hour conversion) lives in domain object

#### Defer?
This refactoring has low immediate value. Consider deferring until Phase 1 & 2 are complete.

---

### Phase 4: Simplify Field Processing Logic (Medium Priority)

**Refactoring**: Extract Method / Tell Don't Ask
**Effort**: Medium (2-3 hours)
**Risk**: Medium
**Benefit**: Medium - Clearer responsibilities

#### Goal
Reduce complexity in `Field.process_line` method.

#### Current Issues
- 50-line method doing too much
- Multiple levels of nesting
- Excessive interrogation of `FieldLine` and `Options`

#### Proposed Refactoring

```crystal
# Before: 50-line method
private def process_line(line : String, skip : Bool, output : Output,
                        transformation : Proc, options : Options,
                        mapping : FieldMapping, logger : Log)
  return if skip
  # ... 45 more lines
end

# After: Composed methods
private def process_line(line : String, skip : Bool, output : Output,
                        transformation : Proc, options : Options,
                        mapping : FieldMapping, logger : Log)
  return if skip

  field_line = parse_field_line(line, options, mapping, logger)
  transformed = transform_fields(field_line, options.fields, transformation, logger)

  output_result(transformed, field_line, output)
end

private def parse_field_line(line, options, mapping, logger) : FieldLine
  FieldLine.parse(line, delimiter: options.delimiter, mapping: mapping, logger: logger)
end

private def transform_fields(field_line, fields, transformation, logger) : Array(String)
  # Extract transformation logic
end

private def output_result(transformed_values, field_line, output)
  # Extract output logic
end
```

#### Benefits
- Each method has single responsibility
- Easier to test individual steps
- Better names reveal intent
- Reduced cognitive load

---

### Phase 5: Eliminate Magic Numbers and Strings (Low Priority)

**Refactoring**: Replace Magic Number with Symbolic Constant
**Effort**: Low (1 hour)
**Risk**: Very Low
**Benefit**: Low - Better readability

#### Examples

```crystal
# Before
if verbose >= 3
  Log::Severity::Trace
elsif verbose >= 2
  Log::Severity::Debug
elsif verbose >= 1
  Log::Severity::Info

# After
module Logging
  TRACE_VERBOSITY = 3
  DEBUG_VERBOSITY = 2
  INFO_VERBOSITY = 1

  if verbose >= TRACE_VERBOSITY
    Log::Severity::Trace
  elsif verbose >= DEBUG_VERBOSITY
    Log::Severity::Debug
  elsif verbose >= INFO_VERBOSITY
    Log::Severity::Info
```

```crystal
# Before
hour == 12 ? 12 : hour + 12  # Magic 12 appears twice

# After
NOON_HOUR = 12
HOURS_IN_HALF_DAY = 12

hour == NOON_HOUR ? NOON_HOUR : hour + HOURS_IN_HALF_DAY
```

---

### Phase 6: Improve Test Organization (Low Priority)

**Refactoring**: Extract Helper Methods
**Effort**: Low (1-2 hours)
**Risk**: Very Low
**Benefit**: Low - Cleaner tests

#### Goal
Reduce duplication in test files.

#### Current Duplication
```crystal
# Repeated pattern in multiple tests
output, status = run_zone_with_input(input, "--utc", "--iso8601")
status.should eq(0)
output.should match(/pattern/)
```

#### Proposed Helpers
```crystal
def expect_successful_conversion(input : String, expected_pattern : Regex,
                                 format : String = "--iso8601")
  output, status = run_zone_with_input(input, "--utc", format)
  status.should eq(0)
  output.should match(expected_pattern)
end

# Usage
it "parses compact date" do
  expect_successful_conversion("20251121", /2025-11-21/)
end
```

---

## Implementation Roadmap

### Sprint 1: Pattern Strategy (Week 1-2)
- [ ] Design `TimestampPattern` abstract class
- [ ] Create pattern classes for all existing formats
- [ ] Write unit tests for each pattern class
- [ ] Migrate `timestamp_patterns.cr` to use pattern objects
- [ ] Update `parse_string` to iterate over pattern instances
- [ ] Remove deprecated constants and case statements
- [ ] Full test suite passing

**Exit Criteria**: All patterns are classes, old code removed, 100% tests passing

### Sprint 2: Extract Parser (Week 3)
- [ ] Create `TimestampParser` class
- [ ] Move parsing methods from `Timestamp` to `TimestampParser`
- [ ] Update `Timestamp.parse` to delegate
- [ ] Verify all tests pass
- [ ] Update documentation

**Exit Criteria**: Clear separation between parsing and timestamp behavior

### Sprint 3: Field Processing Cleanup (Week 4)
- [ ] Break down `process_line` into smaller methods
- [ ] Extract `transform_fields` helper
- [ ] Extract `output_result` helper
- [ ] Add unit tests for new methods
- [ ] Verify integration tests still pass

**Exit Criteria**: No method longer than 15 lines in `field.cr`

### Sprint 4: Polish (Week 5)
- [ ] Replace magic numbers with constants
- [ ] Extract test helpers
- [ ] Update documentation
- [ ] Code review and final adjustments

**Exit Criteria**: All refactorings complete, documentation updated

---

## Risk Mitigation

### High-Risk Refactorings
1. **Pattern Strategy Refactoring** (Phase 1)
   - Risk: Breaking pattern matching behavior
   - Mitigation: Migrate one pattern at a time, run full suite after each
   - Rollback: Keep old code until all patterns migrated

2. **Parser Extraction** (Phase 2)
   - Risk: Breaking public API
   - Mitigation: Use delegation pattern, maintain same interface
   - Rollback: Single commit reversion

### Testing Strategy
- Run full test suite after each atomic refactoring
- No refactoring proceeds if tests fail
- Integration tests must remain unchanged (only implementation changes)
- Consider adding performance benchmarks to catch regressions

### Rollback Plan
Each phase is committed separately, allowing easy rollback:
1. Identify failing commit with `git bisect`
2. Revert specific commit: `git revert <commit-hash>`
3. Fix forward or stay reverted based on severity

---

## Success Metrics

### Code Quality Metrics
- **Lines of Code**: Expect 10-15% reduction through deduplication
- **Cyclomatic Complexity**: Reduce average method complexity by 20%
- **Test Coverage**: Maintain 100% coverage throughout
- **Method Length**: No method over 20 lines (target: average 10 lines)

### Architectural Metrics
- **Coupling**: Reduce inter-class dependencies
- **Cohesion**: Increase single-responsibility adherence
- **Extensibility**: New timestamp patterns require only 1 new class (vs 4 edits currently)

### Developer Experience
- **Onboarding**: New contributors can add timestamp format in <30 minutes
- **Bug Fix Time**: Reduce average time to locate and fix bugs
- **Feature Velocity**: Increase rate of feature additions

---

## Deferred Refactorings

These refactorings were considered but deferred for future consideration:

### 1. Replace Conditional with Polymorphism in `convert_to_24hour`
**Reason**: Current solution is clear and simple. Polymorphism would be over-engineering.

### 2. Introduce Null Object for Missing Timezones
**Reason**: Current error handling is explicit and appropriate for the domain.

### 3. Replace Inheritance with Delegation in Error Handling
**Reason**: Exception hierarchy is simple and standard Crystal practice.

### 4. Extract Interface for FieldLine
**Reason**: Crystal uses structural typing; explicit interfaces not needed.

---

## Conclusion

This refactoring plan follows Martin Fowler's disciplined approach to improving code incrementally while maintaining safety through tests. The phased approach allows us to realize benefits early (Phase 1) while deferring lower-value work.

**Key Takeaways**:
1. Pattern Strategy refactoring (Phase 1) provides highest value
2. Each phase maintains green tests
3. Small commits enable easy rollback
4. Defer low-value refactorings until clear benefit emerges

**Next Steps**:
1. Review this plan with team
2. Begin Phase 1: Pattern Strategy implementation
3. Track metrics before/after each phase
4. Adjust plan based on learnings

---

## References

- Fowler, Martin. *Refactoring: Improving the Design of Existing Code* (2nd Edition)
- Current Zone codebase: `src/zone/`
- Test suite: `spec/`
- Issues fixed: `issues.md`
