# Zone

Timezone conversion and datetime formatting for the command line

```bash
# Convert to your local timezone (default behavior)
zone 2025-11-05T02:40:32+00:00
# => Nov 05, 2025 - 9:40 PM EST

# Fuzzy timezone matching
zone --zone tokyo 2025-11-05T02:40:32+00:00
# => Nov 05, 2025 - 11:40 AM JST

# Process CSV timestamps (field mode)
cat data.csv | zone --field 3 --delimiter ',' --zone pacific
# => customer,purchase_date,amount
# => alice,42.00,Nov 04, 2025 - 6:40 PM PST

# Make logs readable (pattern mode - default)
tail -f app.log | zone
# => Nov 04, 2025 - 9:15 PM EST [ERROR] Database connection timeout
```

## Installation

```bash
gem install zone
```

Or with Bundler:

```bash
bundle add zone
```

## How It Works

Zone operates in two modes:

**Pattern Mode (Default)**: Finds and converts timestamps in arbitrary text. Zone automatically detects timestamps using smart regex patterns and updates them in place. This is like `bat` for timestamps - text goes in, formatted timestamps come out.

```bash
echo "Event at 2025-01-15T10:30:00Z completed" | zone --pretty
# => Event at Jan 15, 2025 - 10:30 AM UTC completed
```

**Field Mode (Explicit)**: Splits lines by delimiter, converts a specific field, then rejoins. Use this for structured data like CSV or TSV files.

```bash
echo "alice,1736937000,active" | zone --field 2 --delimiter ',' --pretty
# => alice,Jan 15, 2025 - 10:30 AM UTC,active
```

Field mode requires both `--field` and `--delimiter` flags.

**Idempotency**: Zone can parse its own output formats, so you can pipe zone output back through zone:

```bash
zone "2025-01-15T10:30:00Z" --pretty | zone --unix
# => 1736937000
```

## Usage

Convert timezones:

```bash
zone --zone 'New York' '2025-11-05T02:40:32+00:00'
# => Nov 04, 2025 - 9:40 PM EST
```

Change formats:

```bash
# Pretty format 1: 12-hour with AM/PM (default)
zone -p 1 '2025-01-15T10:30:00Z'
# => Jan 15, 2025 - 10:30 AM UTC

# Pretty format 2: 24-hour
zone -p 2 '2025-01-15T10:30:00Z'
# => Jan 15, 2025 - 10:30 UTC

# Pretty format 3: ISO-compact
zone -p 3 '2025-01-15T10:30:00Z'
# => 2025-01-15 10:30 UTC

# Unix timestamp
zone --unix '2025-01-15T10:30:00Z'
# => 1736937000

# Custom format
zone --strftime '%Y-%m-%d %H:%M' '2025-11-05T02:40:32+00:00'
# => 2025-11-05 02:40
```

Process structured data:

```bash
# Convert column 2 with explicit delimiter
cat events.csv | zone --field 2 --delimiter ',' --zone UTC

# Skip header row, use tab delimiter
zone --field 2 --delimiter '\t' --headers < data.tsv

# Regex delimiter (outputs as tabs)
echo "alice    1736937000    active" | zone --field 2 --delimiter '/\s+/' --pretty
# => alice	Jan 15, 2025 - 10:30 AM UTC	active
```

Multiple timestamps:

```bash
zone 1730772120 1730858520 1730944920 --zone tokyo --pretty
# => Nov 05 - 11:42 AM JST
# => Nov 06 - 11:42 AM JST
# => Nov 07 - 11:42 AM JST
```

## Options

**Output Formats**

- `-p, --pretty [STYLE]` - Pretty format (1=12hr, 2=24hr, 3=ISO-compact, default: 1)
- `--iso8601` - ISO 8601 format
- `--unix` - Unix timestamp
- `--strftime FORMAT` - Custom strftime format

**Timezones**

- `--zone TZ` - Convert to timezone (fuzzy matching, default: local)
- `--utc` - Convert to UTC
- `--local` - Convert to local time (default)

**Data Processing**

- `--field N` - Field index or name to convert (requires --delimiter)
- `--delimiter PATTERN` - Field separator (string or /regex/)
- `--headers` - Skip first line as headers (requires --field)

**Other**

- `--color MODE` - Colorize output (auto, always, never, default: auto)
- `--verbose` - Show debug output
- `--help` - Show help

## Examples

**Pattern Mode**: Find and convert timestamps in arbitrary text:

```bash
# Logs with embedded timestamps (converts to local time by default)
grep "ERROR" app.log | zone

# Multiple timestamps per line
echo "Start: 1736937000, End: 1736940600" | zone
# => Start: Jan 15, 2025 - 5:30 AM EST, End: Jan 15, 2025 - 6:30 AM EST

# Use different pretty formats
echo "Event: 2025-01-15T10:30:00Z" | zone -p 2
# => Event: Jan 15, 2025 - 10:30 UTC

echo "Event: 2025-01-15T10:30:00Z" | zone -p 3
# => Event: 2025-01-15 10:30 UTC

# Mixed formats in same line
echo "Logged in at 2025-01-15T10:30:00Z (1736937000)" | zone --unix
# => Logged in at 1736937000 (1736937000)
```

**Field Mode**: Convert specific columns in structured data:

```bash
# CSV with explicit delimiter
cat trades.csv | zone --field 3 --delimiter ',' --zone 'New York' -p 2

# Tab-separated with headers
zone --field timestamp --delimiter '\t' --headers < data.tsv

# Regex delimiter
echo "alice    1736937000    active" | zone --field 2 --delimiter '/\s+/'
# => alice	Jan 15, 2025 - 5:30 AM EST	active
```

**Idempotent Conversions**: Chain zone commands together:

```bash
# Convert format multiple times
zone "2025-01-15T10:30:00Z" -p 2 | zone --unix | zone --zone tokyo
# => Jan 15, 2025 - 19:30 JST

# Process zone's own output
zone "now" | zone --zone berlin -p 3
```

**Color Control**:

```bash
# Force colors even when piping
zone "2025-01-15T10:30:00Z" --color always | less -R

# Disable colors for scripting
zone "2025-01-15T10:30:00Z" --color never
```

**Quick Conversions**:

```bash
zone --zone berlin "3pm PST"
# => 2025-11-05T00:00:00+01:00

zone --zone pacific now
# => 2025-11-04T16:42:15-08:00
```

## Timezone Matching

Zone uses fuzzy matching for timezone names:

```bash
zone --zone pacific     # => US/Pacific
zone --zone tokyo       # => Asia/Tokyo  
zone --zone europe      # => Europe/London (first match)
zone --zone 'US/Eastern' # => US/Eastern (exact match)
```

Use `--verbose` to see which timezone was matched.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/gillisd/zone).

## License

[MIT License](https://opensource.org/licenses/MIT)
