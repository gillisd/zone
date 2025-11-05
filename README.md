# Zone

Timezone conversion and datetime formatting for the command line

```bash
# Fuzzy timezone matching
zone --zone tokyo 2025-11-05T02:40:32+00:00
# => 2025-11-05T11:40:32+09:00

# Process CSV timestamps
cat data.csv | zone --index 3 --zone pacific --pretty
# => customer,purchase_date,amount
# => alice,42.00,Nov 04 - 06:40 PM PST

# Make logs readable
tail -f app.log | zone --pretty --zone local
# => Nov 04 - 09:15 PM EST [ERROR] Database connection timeout
```

## Installation

```bash
gem install zone
```

Or with Bundler:

```bash
bundle add zone
```

## Usage

Convert timezones:

```bash
zone --zone 'New York' '2025-11-05T02:40:32+00:00'
# => 2025-11-04T21:40:32-05:00
```

Change formats:

```bash
zone --unix 'Nov 04 - 06:42 PM PST'
# => 1730775720

zone --strftime '%Y-%m-%d %H:%M' '2025-11-05T02:40:32+00:00'
# => 2025-11-05 02:40
```

Process structured data:

```bash
# Convert column 2, auto-detect delimiter
cat events.csv | zone --index 2 --zone UTC

# Skip header row
zone --headers --delimiter '\t' < data.tsv
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

- `--iso8601` - ISO 8601 format (default)
- `--unix` - Unix timestamp
- `--pretty` - Human-readable (e.g., "Nov 04 - 06:40 PM PST")
- `--strftime FORMAT` - Custom format

**Timezones**

- `--zone TZ` - Convert to timezone (fuzzy matching)
- `--utc` - Convert to UTC
- `--local` - Convert to local time

**Data Processing**

- `--index N` - Column to convert (default: 1)
- `--delimiter PATTERN` - Field separator (auto-detected)
- `--headers` - Skip first line

**Other**

- `--verbose` - Show debug output
- `--help` - Show help

## Examples

Analyze logs across timezones:

```bash
grep "ERROR" app.log | zone --zone local --pretty
```

Convert trading data:

```bash
zone --zone 'New York' --strftime '%H:%M:%S' < trades.csv
```

Quick conversions:

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
