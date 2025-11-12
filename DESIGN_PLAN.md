# Zone CLI - 10/10 Design Plan

## Core Principles

1. **Objects represent domain concepts**, not operations
2. **Objects know how to operate on themselves** (to_*, parse, etc.)
3. **Prefer composition over procedural code**
4. **Use pattern matching** (Rule 2: "Prefer 'in' to 'when'")
5. **Functional chaining** (Rule 4)
6. **No global state**

---

## Domain Objects

### 1. `Zone::Timestamp` (lib/zone/timestamp.rb)

**Concept**: A point in time that knows its format and can convert itself.

**Responsibilities**:
- Parse from multiple input formats
- Convert to different timezones
- Format itself in various ways

**API**:
```ruby
# Creation
timestamp = Timestamp.parse("2025-01-15T10:30:00Z")
timestamp = Timestamp.parse("1736937000") # Unix
timestamp = Timestamp.parse("5 minutes ago") # Natural language

# Conversion (returns NEW Timestamp)
tokyo_time = timestamp.in_zone("Tokyo")
utc_time = timestamp.in_utc
local_time = timestamp.in_local

# Formatting (returns String)
timestamp.to_iso8601     # "2025-01-15T10:30:00Z"
timestamp.to_unix        # 1736937000
timestamp.to_pretty      # "Jan 15, 2025 - 10:30 AM UTC"
timestamp.strftime("%Y-%m-%d")

# Chaining!
Timestamp.parse("now").in_zone("Tokyo").to_pretty
```

**Why this is better**:
- No "TimeParser" - `Timestamp.parse` is a class method
- No "TimeFormatter" - Timestamp knows `to_*` methods
- No "TimezoneConverter" - Timestamp knows `in_zone`
- Follows Ruby's `String#to_i`, `Time#to_s` pattern
- Chainable and immutable

---

### 2. `Zone` Module (lib/zone.rb - just add methods)

**Concept**: Utilities for finding timezones.

**Responsibilities**:
- Fuzzy timezone search
- Return TZInfo objects

**API**:
```ruby
Zone.find("tokyo")        # => TZInfo::Timezone (Asia/Tokyo)
Zone.find("new york")     # => TZInfo::Timezone (America/New_York)
Zone.find("UTC")          # => TZInfo::Timezone (UTC)
```

**Why this is better**:
- Simple module method, not a class
- Clear single responsibility
- Used internally by Timestamp

---

### 3. `Zone::DelimitedLine` (lib/zone/delimited_line.rb)

**Concept**: A line of delimited data with fields that can be transformed.

**Responsibilities**:
- Parse line into fields
- Infer delimiters
- Transform specific fields
- Output back to string

**API**:
```ruby
# Creation
line = DelimitedLine.parse("foo,2025-01-15,bar")
line = DelimitedLine.parse("foo 2025-01-15 bar", delimiter: nil) # auto-detect

# With headers/mapping
mapping = FieldMapping.from_header("name,timestamp,value")
line = DelimitedLine.parse("foo,2025-01-15,bar", mapping: mapping)

# Field access
line[1]           # By index (0-based)
line["timestamp"] # By name (if mapping provided)

# Transformation (mutates, returns self for chaining)
line.transform_field(1) { |value| Timestamp.parse(value).to_iso8601 }

# Output
line.to_s  # "foo,2025-01-15T00:00:00Z,bar"
```

**Why this is better**:
- Represents the domain concept of "a line with fields"
- Not "FieldProcessor" - the line transforms itself
- Clear API for field access and transformation

---

### 4. `Zone::FieldMapping` (lib/zone/field_mapping.rb)

**Concept**: Maps field names to indices.

**Responsibilities**:
- Create from header line
- Map names to indices
- Handle numeric indices (1-based for user, 0-based internally)

**API**:
```ruby
# From header
mapping = FieldMapping.from_header("name,timestamp,value")
mapping["timestamp"]  # => 1
mapping[2]            # => 1 (converts "2" to 0-based index 1)

# Numeric only (no headers)
mapping = FieldMapping.numeric
mapping[1]  # => 0
mapping[2]  # => 1
```

---

### 5. `Zone::CLI` (lib/zone/cli.rb)

**Concept**: Command-line interface orchestrator.

**Responsibilities**:
- Parse options
- Build and wire domain objects
- Process input stream
- **Nothing else**

**Structure**:
```ruby
class CLI
  def run
    parse_options!
    setup_logger!

    transformation = build_transformation
    mapping = build_mapping

    process_lines(transformation, mapping)
  end

  private

  def build_transformation
    zone = @options[:zone] || 'utc'
    format = @options[:format] || :iso8601

    ->(value) do
      Timestamp.parse(value)
        .in_zone(zone)
        .send(format_method(format))
    end
  end

  def process_lines(transformation, mapping)
    each_input_line do |line_text|
      line = DelimitedLine.parse(
        line_text,
        delimiter: @options[:delimiter],
        mapping: mapping,
        logger: @logger
      )

      line.transform_field(@options[:field], &transformation)

      puts line.to_s
    end
  end

  def each_input_line
    # Handles ARGV/STDIN/timestamp arguments detection
    # Yields each line
  end

  def format_method(format_sym)
    case format_sym
    in :iso8601 then :to_iso8601
    in :unix then :to_unix
    in :pretty then :to_pretty
    in :strftime then ->{ _1.strftime(@options[:strftime_format]) }
    end
  end
end
```

**Why this is better**:
- Only coordinates - doesn't contain business logic
- Domain objects do the work
- ~150 lines instead of 260+
- Easy to test (mock domain objects)

---

## File Structure

```
lib/
  zone.rb                    # Module with ::find, requires all files
  zone/
    version.rb
    timestamp.rb             # Core domain object (~80 lines)
    delimited_line.rb        # Field handling (~60 lines)
    field_mapping.rb         # Simple mapping (~30 lines)
    cli.rb                   # Orchestration (~150 lines)

exe/
  zone                       # Just calls Zone::CLI.run(ARGV)
```

**Total: ~320 lines** (vs current 335, but much better organized)

---

## Key Improvements Over Current Design

### 1. No "-er" Classes
- ❌ TimeParser → ✅ `Timestamp.parse`
- ❌ TimeFormatter → ✅ `timestamp.to_iso8601`
- ❌ TimezoneConverter → ✅ `timestamp.in_zone`
- ❌ FieldProcessor → ✅ `line.transform_field`

### 2. Ruby Idioms
- Class methods for creation (`parse`, `from_header`)
- Instance methods for conversion (`to_*`, `in_*`)
- Chainable methods return appropriate objects
- Pattern matching throughout

### 3. Testability
Each class can be tested independently:
```ruby
# Test Timestamp
assert Timestamp.parse("now").is_a?(Timestamp)
assert_equal "2025-01-15T00:00:00Z", Timestamp.parse("2025-01-15").to_iso8601

# Test DelimitedLine
line = DelimitedLine.parse("a,b,c")
line.transform_field(1) { |v| v.upcase }
assert_equal "a,B,c", line.to_s

# Test CLI (with mocks)
# Mock input/output, verify domain objects called correctly
```

### 4. Clear Responsibilities
- **Timestamp**: Time domain logic
- **DelimitedLine**: Field parsing/transformation
- **FieldMapping**: Name → Index mapping
- **Zone**: Timezone finding
- **CLI**: Wiring only

### 5. Immutability Where It Makes Sense
- `Timestamp#in_zone` returns NEW Timestamp
- `DelimitedLine#transform_field` mutates (performance for stream processing)
- Clear which methods mutate vs return new

---

## Pattern Matching Usage (Rule 2)

Throughout the design:

```ruby
# In Timestamp.parse
case input
in Time | DateTime | Date then convert_to_time(input)
in /^[0-9\.]+$/ => str then parse_unix(str)
in /...natural language.../ then parse_relative($~)
else DateTime.parse(input).to_time
end

# In CLI
case @options
in { strftime: String } then :strftime
in { unix: true } then :unix
in { pretty: true } then :pretty
else :iso8601
end

# In DelimitedLine#infer_delimiter
case [line, @delimiter]
in [_, String => d] then d
in [/,\s*/, nil] then /,\s*/
in [/\t/, nil] then "\t"
else /\s+/
end
```

---

## Functional Chaining (Rule 4)

```ruby
# Users can write beautiful code
Timestamp.parse("2025-01-15")
  .in_zone("Tokyo")
  .to_pretty

# Processing is clear
input_lines
  .map { |text| DelimitedLine.parse(text, mapping: mapping) }
  .each { |line| line.transform_field(1, &transformation) }
  .each { |line| puts line.to_s }
```

---

## Why This Is 10/10

1. ✅ **No "-er" classes** - Objects represent concepts
2. ✅ **Ruby idioms** - to_*, parse, class methods
3. ✅ **Single Responsibility** - Each class does ONE thing
4. ✅ **Testable** - Can test each class independently
5. ✅ **Minimal coupling** - Classes don't depend on each other unnecessarily
6. ✅ **No global state** - Logger injected, no $variables
7. ✅ **Pattern matching** - Used throughout (Rule 2)
8. ✅ **Functional style** - Chainable, clear data flow (Rule 4)
9. ✅ **Clean CLI** - Just wiring, ~150 lines
10. ✅ **Follows docs** - Read and applied Ruby patterns (Rule 1)

---

## Implementation Plan

1. Create `Timestamp` class with full parsing/formatting
2. Add `Zone.find` module method
3. Create `DelimitedLine` and `FieldMapping`
4. Refactor `CLI` to just orchestrate
5. Delete old files
6. Test thoroughly
