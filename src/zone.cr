require "./zone/version"
require "./zone/field_mapping"
require "./zone/field_line"
require "./zone/timestamp"
require "./zone/cli"

module Zone
  class Error < Exception; end

  ZONEINFO_DIR = "/usr/share/zoneinfo"

  # Files to exclude from timezone enumeration
  EXCLUDED_FILES = [
    "iso3166.tab", "leap-seconds.list", "leapseconds",
    "localtime", "posixrules", "tzdata.zi",
    "zone.tab", "zone1970.tab", "zonenow.tab"
  ]

  @@all_timezones : Array(String)?

  def self.all_timezones : Array(String)
    @@all_timezones ||= begin
      zones = [] of String

      # Recursively find all timezone files
      Dir.glob("#{ZONEINFO_DIR}/**/*").each do |path|
        next unless File.file?(path) || File.symlink?(path)

        # Get relative path from zoneinfo dir
        relative = path.sub("#{ZONEINFO_DIR}/", "")

        # Skip excluded files and files starting with +/- (Etc/GMT offsets handled separately)
        next if EXCLUDED_FILES.includes?(relative)
        next if relative.starts_with?("+") || relative.starts_with?("-")

        # Skip files in root directory (like CET, EST, etc. - these are valid but duplicates)
        # Actually, keep them as they are valid timezone IDs

        zones << relative
      end

      zones.sort!
      zones
    end
  end

  def self.find(keyword : String) : Time::Location?
    # Try direct lookup
    begin
      return Time::Location.load(keyword)
    rescue
    end

    # Try fuzzy search
    search_fuzzy(keyword)
  end

  private def self.search_fuzzy(keyword : String) : Time::Location?
    zones = all_timezones

    # Normalize keyword: replace spaces with wildcards for matching
    normalized_keyword = keyword.gsub(/\s+/, ".*")

    # Try US wildcard pattern first
    us_pattern = Regex.new(
      normalized_keyword.gsub(/^(?:US)?\/?/, "US/") + ".*",
      Regex::Options::IGNORE_CASE
    )

    # Then try global pattern
    global_pattern = Regex.new(
      ".*#{normalized_keyword}.*",
      Regex::Options::IGNORE_CASE
    )

    # Search for US zones first
    found = zones.find { |zone| zone =~ us_pattern }

    # If not found, search globally
    found ||= zones.find { |zone| zone =~ global_pattern }

    return nil unless found

    begin
      Time::Location.load(found)
    rescue
      nil
    end
  end
end

# Main entry point
Zone::CLI.run(ARGV)
