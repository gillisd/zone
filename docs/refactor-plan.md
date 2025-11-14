# CLI Refactor Plan

## Current Problems

1. `lib/zone/cli.rb` violates single responsibility principle
2. Mixing concerns: option parsing, transformations, coloring, I/O, business logic
3. Using ad-hoc regex for timestamp detection instead of TimestampPatterns
4. Not subclassing OptionParser idiomatically
5. Leaking domain concepts like "pattern mode" into CLI

## Proposed Class Structure

### Zone::Options < OptionParser
**Responsibility:** Parse command-line options

```ruby
module Zone
  class Options < OptionParser
    attr_reader :field, :delimiter, :zone, :format, :color, :headers

    def initialize
      super
      @field = nil
      @delimiter = nil
      # ... other options
      setup
    end

    private

    def setup
      self.banner = "Usage: zone [options] [timestamps...]"
      # Define all options here
    end
  end
end
```

**Methods:**
- `#initialize` - Setup default values
- `#setup` - Define option flags (private)
- Inherit `#parse!` from OptionParser

**Returns:** Self (Options instance with parsed values)

### Zone::Input
**Responsibility:** Provide input lines/timestamps

```ruby
module Zone
  class Input
    def initialize(argv, stdin: $stdin)
      @argv = argv
      @stdin = stdin
    end

    def each_line(&block)
      source.each(&block)
    end

    private

    def source
      if timestamps_from_arguments?
        @argv
      elsif @argv.any? || !@stdin.tty?
        @stdin.each_line(chomp: true)
      else
        [Time.now.to_s]
      end
    end

    def timestamps_from_arguments?
      @argv.all? { |arg| TimestampPatterns.match?(arg) }
    end
  end
end
```

**Methods:**
- `#each_line` - Yield each line of input
- `#source` - Determine input source (private)
- `#timestamps_from_arguments?` - Use TimestampPatterns, not ad-hoc regex

### Zone::Output
**Responsibility:** Write colorized output

```ruby
module Zone
  class Output
    def initialize(color_mode: 'auto', stream: $stdout)
      @stream = stream
      @colors = colorize(color_mode)
    end

    def puts(text, highlight: nil)
      output = if highlight
        text.sub(highlight, @colors.cyan(highlight))
      else
        text
      end
      @stream.puts(output)
    end

    def colorize_timestamp(timestamp)
      @colors.cyan(timestamp)
    end

    private

    def colorize(mode)
      case mode
      when 'always' then Colors::ANSI
      when 'never' then Colors::PlainText
      when 'auto' then Colors.colors(@stream)
      end
    end
  end
end
```

**Methods:**
- `#puts` - Write line with optional highlighting
- `#colorize_timestamp` - Colorize a timestamp string
- `#colorize` - Determine color module (private)

### Zone::CLI (Refactored)
**Responsibility:** Orchestrate the command

```ruby
module Zone
  class CLI
    def self.run(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv
    end

    def run
      options = Options.new
      options.parse!(@argv)

      validate!(options)

      input = Input.new(@argv)
      output = Output.new(color_mode: options.color)

      if options.field
        process_fields(input, output, options)
      else
        process_patterns(input, output, options)
      end
    rescue OptionParser::ParseError => e
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{e.message}"
      exit 1
    end

    private

    def validate!(options)
      validate_timezone!(options.zone)
      validate_field_mode!(options.field, options.delimiter)
    end

    def process_fields(input, output, options)
      # Field mode logic (currently in process_field_mode)
    end

    def process_patterns(input, output, options)
      # Pattern mode logic (currently in process_pattern_mode)
    end
  end
end
```

**Methods:**
- `.run` - Class method entry point
- `#initialize` - Store argv
- `#run` - Main orchestration
- `#validate!` - Validation (private)
- `#process_fields` - Field mode (private)
- `#process_patterns` - Pattern mode (private)

## New Module: Zone::Transform
**Responsibility:** Build transformation lambdas

```ruby
module Zone
  module Transform
    module_function

    def build(zone:, format:)
      ->(value) do
        timestamp = Timestamp.parse(value)
        converted = convert_zone(timestamp, zone)
        format_timestamp(converted, format)
      end
    end

    def convert_zone(timestamp, zone_name)
      case zone_name
      in 'utc' | 'UTC' then timestamp.in_utc
      in 'local' then timestamp.in_local
      else timestamp.in_zone(zone_name)
      end
    end

    def format_timestamp(timestamp, format_spec)
      case format_spec
      in :to_iso8601 | :to_unix then timestamp.send(format_spec)
      in { pretty: Integer => style } then timestamp.to_pretty(style)
      in { strftime: String => fmt } then timestamp.strftime(fmt)
      end
    end
  end
end
```

## Changes to TimestampPatterns

Add a `match?` method for detecting timestamps:

```ruby
module TimestampPatterns
  module_function

  def match?(text)
    patterns.any? { |pattern| pattern.match?(text) }
  end
end
```

## Migration Strategy

1. Create new files: `lib/zone/options.rb`, `lib/zone/input.rb`, `lib/zone/output.rb`, `lib/zone/transform.rb`
2. Extract logic from cli.rb into new classes
3. Refactor cli.rb to use new classes
4. Test each piece independently
5. Delete old code from cli.rb

## Benefits

- **Single Responsibility**: Each class has one job
- **Testability**: Easy to unit test Input, Output, Transform separately
- **Clarity**: No leaking of "pattern mode" into option parsing
- **Reusability**: Transform module can be used elsewhere
- **Idiomatic**: Options subclasses OptionParser as Ruby community does
- **Uses existing code**: TimestampPatterns for detection, Colors for output
