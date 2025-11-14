## [Unreleased]

### Added

#### --color Flag
Added `--color` flag with three modes for controlling ANSI color output:
- `auto` (default): Colors when stdout is a TTY device
- `always`: Always show colors (useful for piping to `less -R`)
- `never`: Never show colors (useful for scripting and CI)

Both pattern mode and field mode now respect this setting and colorize converted timestamps in cyan.

#### Pretty Format Variants
Implemented `-p [STYLE]` / `--pretty [STYLE]` with three preset formats:
- `-p 1`: `Jan 15, 2025 - 10:30 AM EST` (12-hour with AM/PM) - default
- `-p 2`: `Jan 15, 2025 - 22:30 EST` (24-hour for international users)
- `-p 3`: `2025-01-15 22:30 EST` (ISO-style compact, sortable)

All three formats include the year and timezone abbreviation, emphasizing zone's core conversion feature over simple formatting.

### Changed

#### New Defaults for Better UX
- **Default format**: Changed from ISO8601 to pretty format 1 (12-hour with AM/PM)
- **Default timezone**: Changed from UTC to local timezone

These changes give new users immediate visual feedback, showing the tool's value on first use. Users running `zone "2025-01-15T10:30:00Z"` now see their local time in a readable format instead of unchanged ISO8601.

#### Updated Pattern Matching
- Added patterns for all three pretty output formats (P03-P05)
- Renumbered unix timestamp pattern to P06
- Renumbered relative time pattern to P07
- Zone maintains full idempotency: can parse all its own output formats

### Technical Details

**Files Modified:**
- `lib/zone/timestamp.rb`: Updated `to_pretty(style)` to accept style parameter (1/2/3)
- `lib/zone/timestamp_patterns.rb`: Added P03-P05 patterns for pretty formats, updated validation
- `lib/zone/cli.rb`:
  - Added `--color` option with auto/always/never modes
  - Added `colorize(stream)` helper method
  - Changed default timezone from UTC to local
  - Changed default format from ISO8601 to pretty1
  - Updated `determine_format_method` to handle pretty style variants
  - Added color support to field mode output via `sub()` replacement
- `README.md`: Updated all examples, options, and documentation

**Backward Compatibility:**
- This is a **breaking change** for scripts that relied on default ISO8601/UTC output
- Users who want the old behavior should explicitly specify `--iso8601 --utc`
- The `--pretty` flag behavior changed from a boolean to accepting an optional integer style

**Testing Verified:**
- ✓ All three pretty formats produce correct output
- ✓ Default behavior shows pretty1 with local timezone
- ✓ Color modes work correctly (auto/always/never)
- ✓ Field mode colorizes transformed timestamps
- ✓ Idempotency maintained: zone can parse its own output
- ✓ Pattern matching recognizes all zone output formats

### Rationale

**Why these three formats?**

1. **Format 1 (12hr)**: Most readable for North American users, matches human conversation style
2. **Format 2 (24hr)**: International standard, technical contexts, no AM/PM ambiguity
3. **Format 3 (ISO-compact)**: Sortable, structured, good for logs and data processing

All formats prioritize **conversion** (showing timezone) over pure **formatting** (date-only output), aligning with the tool's name and purpose.

**Why default to local timezone?**

The principle of least surprise: users running timezone conversion tools expect to see their local time. UTC is correct for APIs and storage, but humans think in local time. Power users who need UTC will specify `--utc` explicitly.

**Why default to pretty format?**

Immediate visual feedback shows the tool working. Seeing "Jan 15, 2025 - 10:30 AM EST" is instantly recognizable as a timestamp conversion. ISO8601 output looks identical to input for many timestamps, giving no feedback that anything happened.

## [0.1.0] - 2025-11-04

- Initial release
