# Zone



## Installation


Install the gem and add to the application's Gemfile by executing:

```bash
bundle add zone
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install zone
```

## Usage

**zone** can convert time-zones:
```shell
# uses a fuzzy search to match any time-zone keyword you input

zone --pretty --zone 'pacific' 2025-11-05T02:40:32+00:00

# => Nov 04 - 06:40 PM PST


```

**zone** can convert datetime formats:
```shell
zone --iso8601 --zone 'Europe' "Nov 04 - 06:42 PM PST"

# => 2025-11-05T03:42:00+01:00

zone --zone Tokyo --strftime '%Y-%m-%d %-I:%M %p %Z' 'Nov 04 - 06:42 PM PST'

# => 2025-11-05 11:42 AM JST

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gillisd/zone.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
