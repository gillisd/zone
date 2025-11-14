# Field Processing - Bounded Context Analysis

## The Problem Domain

**Line-oriented field processing** appears in many contexts:
- CSV/TSV transformation
- Log file processing
- Data format conversion
- Stream processing of delimited data

Current tools:
- **awk**: Numeric field access (`$1`, `$2`), powerful but cryptic
- **Ruby `-lane`**: Splits into `$F` array, numeric indices only
- **cut/paste**: Unix utilities, limited transformation
- **csvkit**: Python-based, but heavyweight

**Gap**: No lightweight Ruby tool for field processing with **named field access**.

---

## Bounded Context Definition

### Input
- Stream of text lines
- Lines have delimited fields (CSV, TSV, space-separated, etc.)
- Optional header line with field names

### Processing
- Access fields by:
  - **Name** (if header provided): `line["timestamp"]`
  - **Index** (1-based like awk, or 0-based): `line[2]` or `line.field(2)`
- Transform fields with blocks
- Preserve untransformed fields

### Output
- Reconstructed lines with same delimiter
- Maintain field order
- Preserve formatting where possible

---

## Use Cases

### 1. **Zone CLI** (Current Application)
```bash
echo "log,2025-01-15T10:30:00Z,info" | zone --field 2 --zone Tokyo
# => log,2025-01-15T19:30:00+09:00,info
```

### 2. **Generic Field Transformation**
```ruby
# Convert temperatures from F to C
ARGF.each_line do |line|
  fields = FieldLine.parse(line)
  fields.transform(3) { |f| (f.to_f - 32) * 5/9 }
  puts fields.to_s
end
```

### 3. **Named Field Access**
```ruby
# With header: name,temp_f,humidity
mapping = FieldMapping.from_header(ARGF.readline)

ARGF.each_line do |line|
  fields = FieldLine.parse(line, mapping: mapping)
  fields.transform("temp_f") { |f| (f.to_f - 32) * 5/9 }
  puts fields.to_s
end
```

### 4. **Ruby -lane Replacement**
```bash
# Instead of: ruby -lane 'puts $F[1].upcase' data.txt
# Could be:   fields --transform 2 'upcase' data.txt
```

---

## Core Abstractions

### 1. `FieldLine` - The Line with Fields

**Concept**: A parsed line that knows its fields and can transform them.

```ruby
class FieldLine
  # Creation
  def self.parse(text, delimiter: nil, mapping: nil)
    # Auto-detect delimiter if nil
    # Use mapping for name->index if provided
  end

  # Access (read-only)
  def [](index_or_name)
    # Return field value
    # Handle both numeric and named access
  end

  def fields
    # Return array of all field values
  end

  # Transformation (mutates)
  def transform(index_or_name, &block)
    # Transform specified field
    # Returns self for chaining
  end

  def transform_all(&block)
    # Transform all fields
    # Returns self
  end

  # Output
  def to_s
    # Reconstruct line with delimiter
  end

  def to_a
    # Return field array
  end

  # Chainable
  def then(&block)
    # Ruby's then for chaining
  end
end
```

**Usage**:
```ruby
line = FieldLine.parse("foo,bar,baz")
line[1]                           # => "bar" (0-based)
line.transform(1, &:upcase)       # Mutates field 1
line.to_s                         # => "foo,BAR,baz"

# With mapping
mapping = FieldMapping.from_header("name,value,unit")
line = FieldLine.parse("temp,72,F", mapping: mapping)
line["value"]                     # => "72"
line.transform("value") { |v| v.to_i + 10 }
line.to_s                         # => "temp,82,F"
```

---

### 2. `FieldMapping` - Name to Index Resolution

**Concept**: Maps field names to indices, handles both.

```ruby
class FieldMapping
  # Creation
  def self.from_header(header_line, delimiter: nil)
    # Parse header, create name->index map
  end

  def self.numeric
    # No names, just convert 1-based to 0-based
  end

  # Resolution
  def resolve(key)
    # key can be String (name) or Integer (index)
    # Returns 0-based index
  end

  def [](key)
    # Alias for resolve
  end

  def names
    # Return array of field names (if header-based)
  end
end
```

**Usage**:
```ruby
# With header
mapping = FieldMapping.from_header("name,age,city")
mapping["age"]      # => 1 (0-based index)
mapping[2]          # => 1 (convert 1-based to 0-based)
mapping.names       # => ["name", "age", "city"]

# Numeric only
mapping = FieldMapping.numeric
mapping[1]          # => 0
mapping[2]          # => 1
```

---

### 3. `DelimiterDetector` - Delimiter Inference

**Concept**: Infers delimiter from line content.

```ruby
class DelimiterDetector
  def self.infer(line, explicit_delimiter: nil)
    # If explicit provided, use it (handle /regex/ strings)
    # Otherwise detect: comma, tab, whitespace
    # Returns delimiter (String or Regexp)
  end
end
```

**Usage**:
```ruby
DelimiterDetector.infer("foo,bar,baz")           # => ","
DelimiterDetector.infer("foo\tbar\tbaz")         # => "\t"
DelimiterDetector.infer("foo  bar   baz")        # => /\s+/
DelimiterDetector.infer("foo|bar", explicit: "|") # => "|"
```

---

## Design Patterns from Ruby Docs

### Pattern 1: Objects Know How to Convert Themselves
From `Time` class:
```ruby
time.to_i      # Time knows how to become Integer
time.to_s      # Time knows how to become String
time.strftime  # Time knows how to format itself
```

Applied to `FieldLine`:
```ruby
line.to_s      # FieldLine knows how to become String
line.to_a      # FieldLine knows how to become Array
line.to_h      # FieldLine knows how to become Hash (if mapping)
```

### Pattern 2: Class Methods for Creation
From `Time` class:
```ruby
Time.parse(string)
Time.at(seconds)
Time.new(year, month, day)
```

Applied to `FieldLine`:
```ruby
FieldLine.parse(text)
FieldLine.parse(text, delimiter: ",")
FieldLine.parse(text, mapping: mapping)
```

### Pattern 3: Chainable Transformations
From `Array`:
```ruby
array.map { ... }.select { ... }.first
```

Applied to `FieldLine`:
```ruby
FieldLine.parse(text)
  .transform(1, &:upcase)
  .transform(2) { |v| v.to_i * 2 }
  .to_s
```

### Pattern 4: Pattern Matching for Input Type Detection
From Ruby 3+ pattern matching:
```ruby
case value
in String then ...
in Integer then ...
in /regex/ then ...
end
```

Applied to `FieldLine`:
```ruby
# In resolve_field
case key
in String => name then mapping[name]
in Integer => index then index - 1  # Convert to 0-based
else raise ArgumentError
end
```

---

## Separation from Zone Logic

The key insight: **Field processing is completely independent of timezone conversion.**

### What Belongs in the Bounded Context
✅ Parsing delimited lines
✅ Inferring delimiters
✅ Mapping names to indices
✅ Transforming fields
✅ Reconstructing lines
✅ Field access by name or index

### What Does NOT Belong
❌ Timezone conversion logic
❌ Timestamp parsing
❌ Specific formatting rules
❌ CLI option parsing
❌ Logging

---

## Potential Extraction as Separate Gem

This bounded context could become a gem: **`fieldline`** or **`field_ruby`**

**Value Proposition**:
- Lightweight (no dependencies)
- Ruby-idiomatic API
- Named field access (unlike awk/cut)
- Delimiter auto-detection
- Chainable transformations
- Drop-in replacement for `ruby -lane`

**API Example**:
```ruby
require 'fieldline'

# Simple transformation
FieldLine.parse("foo,bar,baz")
  .transform(1, &:upcase)
  .to_s
# => "foo,BAR,baz"

# With header
mapping = FieldMapping.from_header("name,score,grade")
FieldLine.parse("Alice,95,A", mapping: mapping)
  .transform("score") { |s| s.to_i + 5 }
  .to_s
# => "Alice,100,A"

# Stream processing
mapping = FieldMapping.from_header(ARGF.readline)
ARGF.each_line do |line|
  puts FieldLine.parse(line, mapping: mapping)
    .transform("price") { |p| "$#{p}" }
    .to_s
end
```

**CLI Tool** (optional):
```bash
# Transform field 2 to uppercase
cat data.csv | fieldline transform 2 upcase

# With header, transform by name
fieldline --header transform price 'gsub(/USD/, "EUR")' data.csv
```

---

## Integration with Zone CLI

Zone CLI would **use** this bounded context, not contain it:

```ruby
# In Zone::CLI
def process_lines(transformation, mapping)
  each_input_line do |line_text|
    field_line = FieldLine.parse(
      line_text,
      delimiter: @options[:delimiter],
      mapping: mapping
    )

    field_line.transform(@options[:field]) do |value|
      Timestamp.parse(value)
        .in_zone(@zone)
        .send(@format_method)
    end

    puts field_line.to_s
  end
end
```

**Clean separation**: Zone CLI focuses on timestamp transformation, `FieldLine` focuses on field processing.

---

## Implementation Considerations

### 1. **Delimiter Preservation**
When reconstructing, use the **inferred** delimiter, not the original spacing:
- Input: `"foo   bar    baz"` (irregular spacing)
- After split: `["foo", "bar", "baz"]`
- Delimiter: `/\s+/`
- Output: `"foo\tbar\tbaz"` (normalized to tab)

**Trade-off**: Consistency vs. preservation. Current approach chooses consistency.

### 2. **Field Index Convention**
Two conventions exist:
- **awk**: 1-based (`$1` is first field)
- **Ruby**: 0-based (`array[0]` is first element)

**Solution**: Support both via mapping layer
```ruby
mapping[1]     # => 0 (for awk compatibility)
mapping["name"] # => 0 (for named access)
```

### 3. **Immutability vs. Mutation**
`FieldLine#transform` mutates for performance (stream processing of large files).
Could add immutable variant:
```ruby
line.transform(1, &:upcase)        # Mutates
line.transforming(1, &:upcase)     # Returns new FieldLine
```

### 4. **Error Handling**
What if field doesn't exist?
```ruby
line = FieldLine.parse("a,b,c")
line[10]        # => nil (safe) or raise? (fail-fast)
```

**Recommendation**: Return `nil` by default, add `fetch` variant:
```ruby
line[10]        # => nil
line.fetch(10)  # => raises IndexError
```

---

## Ruby Idioms Applied

### From Reading `ri` Docs:

1. **Array#[]** - Implement `[]` for field access
2. **String#split** - Handle both String and Regexp delimiters
3. **Hash.new with block** - Use for mapping with default behavior
4. **Enumerable** - Make FieldLine enumerable over fields?
5. **to_* methods** - Implement `to_s`, `to_a`, `to_h`

---

## Comparison to Existing Tools

| Feature | awk | ruby -lane | cut | csvkit | fieldline (proposed) |
|---------|-----|------------|-----|--------|---------------------|
| Numeric field access | ✅ $1 | ✅ $F[0] | ✅ -f1 | ✅ | ✅ line[1] |
| Named field access | ❌ | ❌ | ❌ | ✅ | ✅ line["name"] |
| Auto-detect delimiter | ❌ | ✅ | ❌ | ✅ | ✅ |
| Field transformation | ✅ | ✅ | ❌ | ❌ | ✅ |
| Ruby-idiomatic | ❌ | 🟡 | ❌ | ❌ | ✅ |
| Lightweight | ✅ | ✅ | ✅ | ❌ | ✅ |
| Chainable API | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Conclusion

**The field processing logic is a distinct bounded context** that:

1. **Has clear boundaries**: line in → fields → transformed fields → line out
2. **Is domain-agnostic**: Works for any delimited data, not just timestamps
3. **Follows Ruby idioms**: Class methods, `to_*` patterns, chainable
4. **Could be extracted**: Useful as standalone gem
5. **Simplifies Zone CLI**: By handling all field complexity

**Recommendation**:
- Implement as separate classes in `Zone` namespace first
- Keep the door open for extraction to separate gem later
- Focus on clean API and separation of concerns

**Files**:
```
lib/zone/
  field_line.rb           # Core abstraction
  field_mapping.rb        # Name->index resolution
  delimiter_detector.rb   # Delimiter inference (or module in field_line.rb)
```

This keeps the field processing logic isolated and reusable while staying within the Zone project for now.
