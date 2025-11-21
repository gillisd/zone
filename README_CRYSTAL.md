# Zone - Crystal Implementation

This is a Crystal language implementation of the Zone timezone conversion tool. Crystal was chosen for its:
- Built-in comprehensive datetime/timezone library (no external dependencies needed)
- Fast compilation to native code
- Ruby-like syntax making conversion straightforward
- Strong type safety

## Requirements

- Crystal >= 1.0.0 (tested with 1.14.0)
- No external dependencies - uses only Crystal standard library

## Installation

### From Source

1. Clone the repository
2. Build the executable:

```bash
crystal build src/cli.cr --release -o bin/zone
```

### Development Build (Faster)

```bash
crystal build src/cli.cr -o bin/zone
```

## Compilation

### Build the executable

```bash
# Release build (optimized, slower compilation)
crystal build src/cli.cr --release -o bin/zone

# Development build (faster compilation, less optimized)
crystal build src/cli.cr -o bin/zone
```

### Run tests

```bash
# Run all unit tests
crystal spec

# Run specific test file
crystal spec spec/zone/timestamp_spec.cr

# Run with verbose output
crystal spec --verbose
```

### Build and install system-wide

```bash
# Build release version
crystal build src/cli.cr --release -o bin/zone

# Install to /usr/local/bin (requires sudo)
sudo cp bin/zone /usr/local/bin/

# Or install to user bin directory
mkdir -p ~/.local/bin
cp bin/zone ~/.local/bin/
```

## Project Structure

```
├── shard.yml                    # Crystal project configuration
├── src/
│   ├── cli.cr                   # Main executable entry point
│   ├── zone.cr                  # Main module with timezone finding
│   └── zone/
│       ├── version.cr           # Version constant
│       ├── timestamp.cr         # Timestamp parsing and conversion
│       ├── timestamp_patterns.cr # Regex patterns for timestamp detection
│       ├── cli.cr               # CLI interface and error handling
│       ├── options.cr           # Command-line option parsing
│       ├── input.cr             # Input handling (args/stdin)
│       ├── output.cr            # Output formatting and colorization
│       ├── transform.cr         # Timestamp transformation logic
│       ├── pattern.cr           # Pattern mode processing
│       ├── field.cr             # Field mode processing
│       ├── field_line.cr        # Field line parsing
│       ├── field_mapping.cr     # Field name/index mapping
│       ├── colors.cr            # ANSI color support
│       └── logging.cr           # Logging support
├── spec/
│   ├── spec_helper.cr           # Spec configuration
│   ├── zone_spec.cr             # Main module tests
│   ├── integration/             # Integration tests
│   └── zone/                    # Unit tests
│       ├── timestamp_spec.cr
│       ├── field_mapping_spec.cr
│       ├── field_line_spec.cr
│       └── zone_module_spec.cr
└── bin/                         # Compiled executable location
```

## Differences from Ruby Version

### Key Changes

1. **No External Dependencies**: Crystal's standard library includes comprehensive timezone support (`Time::Location`), eliminating the need for the `tzinfo` gem.

2. **Static Typing**: All methods and variables have explicit types, making the code more robust and easier to debug.

3. **Performance**: Crystal compiles to native code, resulting in significantly faster execution than the Ruby version.

4. **No Frozen String Literal**: Crystal doesn't need the `frozen_string_literal` pragma as strings are immutable by default.

### API Compatibility

The command-line interface remains 100% compatible with the Ruby version:

```bash
# All these commands work identically
zone 2025-11-05T02:40:32+00:00
zone --zone tokyo 2025-11-05T02:40:32+00:00
cat data.csv | zone --field 3 --delimiter ',' --zone pacific
tail -f app.log | zone
```

## Development

### Running in Development

```bash
# Run directly without building
crystal run src/cli.cr -- --help

# Run with arguments
crystal run src/cli.cr -- "2025-01-15T10:30:00Z" --zone Tokyo
```

### Testing

```bash
# Run all tests
crystal spec

# Run with coverage (requires additional setup)
crystal spec --error-trace

# Run specific test
crystal spec spec/zone/timestamp_spec.cr
```

### Debugging

```bash
# Build with debug symbols
crystal build src/cli.cr -o bin/zone --debug

# Run with verbose logging
./bin/zone --verbose "2025-01-15T10:30:00Z"
```

## Troubleshooting

### Crystal Not Found

If `crystal` command is not found, install Crystal:

**macOS:**
```bash
brew install crystal
```

**Ubuntu/Debian:**
```bash
curl -fsSL https://crystal-lang.org/install.sh | sudo bash
```

**From Source:**
See https://crystal-lang.org/install/

### Compilation Errors

If you encounter compilation errors:

1. Ensure you have Crystal >= 1.0.0:
   ```bash
   crystal --version
   ```

2. Clean and rebuild:
   ```bash
   rm -rf bin/zone
   crystal build src/cli.cr --release -o bin/zone
   ```

3. Check for syntax errors:
   ```bash
   crystal tool format --check src/
   ```

### Test Failures

If tests fail:

1. Run with verbose output to see details:
   ```bash
   crystal spec --verbose --error-trace
   ```

2. Run individual failing test:
   ```bash
   crystal spec spec/path/to/failing_spec.cr
   ```

## Performance

Crystal's compiled nature provides significant performance advantages:

- **Startup time**: ~10-100x faster than Ruby
- **Execution time**: ~2-10x faster for typical operations
- **Memory usage**: Similar to or better than Ruby

## Contributing

1. Make changes to `.cr` files in `src/` directory
2. Run tests: `crystal spec`
3. Format code: `crystal tool format src/ spec/`
4. Build and test: `crystal build src/cli.cr -o bin/zone && ./bin/zone --help`

## License

MIT License - Same as the original Ruby implementation
