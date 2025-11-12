# Zsh Completion for Zone

Intelligent command-line completion for the `zone` timezone conversion tool.

## Features

- Completes all command-line flags and options
- Suggests common timezone names (UTC, local, America/New_York, etc.)
- Provides example timestamp formats
- Handles mutually exclusive options (e.g., --iso8601 vs --unix)
- Context-aware completions for option values

## Installation

### Method 1: User-specific installation

1. Create a completions directory if it doesn't exist:
   ```bash
   mkdir -p ~/.zsh/completions
   ```

2. Copy the completion script:
   ```bash
   cp completions/_zone ~/.zsh/completions/
   ```

3. Add to your `~/.zshrc` (before `compinit`):
   ```bash
   fpath=(~/.zsh/completions $fpath)
   autoload -U compinit && compinit
   ```

4. Reload your shell:
   ```bash
   exec zsh
   ```

### Method 2: System-wide installation

1. Copy to the system completions directory:
   ```bash
   sudo cp completions/_zone /usr/local/share/zsh/site-functions/
   ```

2. Rebuild completion cache:
   ```bash
   rm -f ~/.zcompdump && compinit
   ```

### Method 3: Oh My Zsh

1. Copy to Oh My Zsh completions:
   ```bash
   cp completions/_zone ~/.oh-my-zsh/completions/
   ```

2. Reload:
   ```bash
   exec zsh
   ```

## Usage

Once installed, press `<Tab>` after typing `zone` to see available completions:

```bash
zone <Tab>               # Shows all options
zone --zone <Tab>        # Shows timezone suggestions
zone --strftime <Tab>    # Prompts for strftime format
zone 2025 <Tab>          # Shows timestamp format examples
```

## Examples

```bash
# Complete timezone names
zone "$(date)" --zone <Tab>
# Suggests: UTC, local, America/New_York, Europe/London, Asia/Tokyo, etc.

# Complete output formats
zone "now" --<Tab>
# Shows: --iso8601, --pretty, --unix, --strftime, etc.

# Mutually exclusive options
zone "now" --unix --<Tab>
# Won't suggest --iso8601, --pretty, or --strftime (incompatible)
```

## Testing

Verify the completion is loaded:
```bash
which _zone
# Should output the path to the completion function
```

Test syntax:
```bash
zsh -n completions/_zone
# Should output nothing (syntax valid)
```

## Troubleshooting

**Completions not working:**
1. Ensure `fpath` includes your completions directory:
   ```bash
   echo $fpath
   ```

2. Verify the completion function is loaded:
   ```bash
   which _zone
   ```

3. Rebuild completion cache:
   ```bash
   rm -f ~/.zcompdump && exec zsh
   ```

**Completions are outdated:**
```bash
# Force rebuild
rm -f ~/.zcompdump*
compinit
```
