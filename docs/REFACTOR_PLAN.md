# Zone CLI Refactor Plan

## Current State

The `exe/zone` file contains:
- All option parsing logic
- Two classes (`TimezoneSearch` and `FieldMap`) embedded in the executable
- Format detection and output logic
- Input handling (ARGV, STDIN, ARGF)
- All business logic mixed together

## Goals

1. **Separation of Concerns**: Each class should have a single, well-defined responsibility
2. **Testability**: Extract logic into testable classes in `lib/zone/`
3. **Idiomatic Ruby**: Use Ruby best practices and OOD principles
4. **Maintainability**: Clear structure that's easy to understand and extend

## Proposed Class Structure

### 1. `Zone::CLI` (lib/zone/cli.rb)
**Responsibility**: Command-line interface orchestration
- Parse options using OptionParser
- Configure and run the application
- Handle ARGV/STDIN input detection
- Coordinate between other components

### 2. `Zone::TimezoneSearch` (lib/zone/timezone_search.rb)
**Responsibility**: Timezone lookup and fuzzy matching
- Already exists but needs extraction
- Keep memoization of all_zones
- Clean up interface

### 3. `Zone::FieldMap` (lib/zone/field_map.rb)
**Responsibility**: Field parsing and manipulation
- Already exists but needs extraction
- Delimiter inference
- Field mapping (by index or name)
- Line splitting and joining

### 4. `Zone::TimeParser` (lib/zone/time_parser.rb)
**Responsibility**: Parse various time formats
- Unix timestamps
- ISO 8601
- Natural language ("5 minutes ago")
- DateTime strings
- Handle Time, DateTime, Date objects

### 5. `Zone::TimeFormatter` (lib/zone/time_formatter.rb)
**Responsibility**: Format time objects for output
- ISO 8601 formatting
- Pretty formatting
- Unix timestamp formatting
- Custom strftime formatting
- Select format based on options

### 6. `Zone::TimezoneConverter` (lib/zone/timezone_converter.rb)
**Responsibility**: Convert times between zones
- Use TimezoneSearch to find zones
- Create callable converters
- Cache converters for performance
- Handle UTC, local, and custom zones

### 7. `Zone::InputProcessor` (lib/zone/input_processor.rb)
**Responsibility**: Process input lines/streams
- Iterate over input (files, STDIN, or arguments)
- Apply field mapping
- Parse timestamps
- Convert timezones
- Format output
- Coordinate FieldMap, TimeParser, TimezoneConverter, and TimeFormatter

### 8. `Zone::Logger` (lib/zone/logger.rb)
**Responsibility**: Structured logging with colors
- Already partially implemented
- Extract configuration
- Reusable across classes

## Migration Strategy

### Phase 1: Extract Existing Classes
1. Move `TimezoneSearch` to `lib/zone/timezone_search.rb`
2. Move `FieldMap` to `lib/zone/field_map.rb`
3. Update `exe/zone` to require these files
4. Ensure no functionality breaks

### Phase 2: Extract New Classes
1. Create `Zone::TimeParser` with all parsing logic
2. Create `Zone::TimeFormatter` with all formatting logic
3. Create `Zone::TimezoneConverter` to encapsulate zone conversion
4. Update `exe/zone` to use new classes

### Phase 3: Create CLI Orchestrator
1. Create `Zone::CLI` to handle option parsing and orchestration
2. Create `Zone::InputProcessor` to handle the main processing loop
3. Simplify `exe/zone` to just instantiate and run `Zone::CLI`

### Phase 4: Extract Logger
1. Move logger configuration to `Zone::Logger`
2. Make it injectable into other classes

## Class Interaction Pattern

```
exe/zone
  └─> Zone::CLI.run(ARGV)
       ├─> Zone::Logger (for logging)
       ├─> OptionParser (parse options)
       ├─> Zone::TimezoneConverter.new(zone_option)
       │    └─> Zone::TimezoneSearch (find timezone)
       └─> Zone::InputProcessor.new(options)
            ├─> Zone::FieldMap (map fields in lines)
            ├─> Zone::TimeParser (parse timestamps)
            ├─> Zone::TimezoneConverter (convert zones)
            └─> Zone::TimeFormatter (format output)
```

## Key Idiomatic Ruby Patterns to Apply

1. **Use `case/in` pattern matching** (already done well)
2. **Prefer functional chaining** for enumerables (Rule 4)
3. **OptionParser with `parse!(into:)`** (Rule 3, already done)
4. **Use `=>` for rightward assignment** where appropriate
5. **Leverage `tap` for side effects**
6. **Use `||=` for memoization** (already done in TimezoneSearch)
7. **Dependency injection** for logger and other dependencies
8. **Module namespacing** under `Zone::`

## Testing Strategy

Once refactored, each class can be tested independently:
- `test/zone/timezone_search_test.rb`
- `test/zone/field_map_test.rb`
- `test/zone/time_parser_test.rb`
- `test/zone/time_formatter_test.rb`
- `test/zone/timezone_converter_test.rb`
- `test/zone/input_processor_test.rb`
- `test/zone/cli_test.rb`

## Benefits

1. **Single Responsibility**: Each class has one clear purpose
2. **Testability**: Can test each component in isolation
3. **Reusability**: Classes can be used independently or in other contexts
4. **Maintainability**: Clear structure makes it easy to find and modify code
5. **Extensibility**: Easy to add new formats, parsers, or features

## Next Steps

1. Review and approve this plan
2. Begin Phase 1 extraction
3. Add comprehensive tests for each extracted class
4. Continue through remaining phases
5. Update documentation
