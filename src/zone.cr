require "./zone/version"
require "./zone/field_mapping"
require "./zone/field_line"
require "./zone/timestamp_pattern"
require "./zone/timestamp_patterns"
require "./zone/timestamp_parser"
require "./zone/timestamp"
require "./zone/cli"

module Zone
  class Error < Exception; end

  # Module-level logger for timezone operations
  @@logger : Log? = nil

  def self.logger=(logger : Log)
    @@logger = logger
  end

  def self.find(keyword : String) : Time::Location?
    # Try exact match first
    begin
      location = Time::Location.load(keyword)
      # Log successful exact match at info level (verbose >= 1)
      @@logger.try &.info { "Matched timezone '#{keyword}' exactly" }
      return location
    rescue
      # Fall through to fuzzy search
    end

    search_fuzzy(keyword)
  end

  # Returns a list of all available IANA timezone names
  private def self.available_timezones : Array(String)
    zones = [] of String

    # Try standard timezone database locations
    zoneinfo_dirs = [
      "/usr/share/zoneinfo/",
      "/usr/share/lib/zoneinfo/",
      "/usr/lib/locale/TZ/",
    ]

    # Check ENV["ZONEINFO"] first
    if custom_zoneinfo = ENV["ZONEINFO"]?
      zoneinfo_dirs.unshift(custom_zoneinfo) unless custom_zoneinfo.ends_with?(".zip")
    end

    zoneinfo_dirs.each do |base_dir|
      next unless Dir.exists?(base_dir)

      scan_zoneinfo_dir(base_dir, base_dir, zones)
      break unless zones.empty?  # Use first successful directory
    end

    zones.sort
  end

  # Recursively scans zoneinfo directory for timezone files
  private def self.scan_zoneinfo_dir(base_dir : String, current_dir : String, zones : Array(String))
    return unless Dir.exists?(current_dir)

    Dir.each_child(current_dir) do |entry|
      path = File.join(current_dir, entry)

      # Skip special files
      next if entry.starts_with?('.') ||
              entry == "posix" ||
              entry == "right" ||
              entry.downcase == "readme" ||
              entry.ends_with?(".tab") ||
              entry.ends_with?(".list")

      if Dir.exists?(path)
        scan_zoneinfo_dir(base_dir, path, zones)
      elsif File.file?(path)
        # Check if file is readable
        begin
          info = File.info(path)
          if info.file? && info.permissions.includes?(File::Permissions::OwnerRead)
            # Extract relative path from base as timezone name
            zone_name = path.lchop(base_dir)
            zones << zone_name unless zone_name.empty?
          end
        rescue
          # Skip files we can't access
        end
      end
    end
  end

  private def self.search_fuzzy(keyword : String) : Time::Location?
    all_zones = available_timezones

    # Normalize keyword: replace spaces with wildcards for matching
    normalized_keyword = keyword.gsub(/\s+/, ".*")

    # Try US wildcard pattern first
    us_pattern = Regex.new(
      normalized_keyword.gsub(/^(?:US)?\//, "US/").gsub(/$/, ".*"),
      Regex::Options::IGNORE_CASE
    )

    # Then try global pattern
    global_pattern = Regex.new(
      ".*#{normalized_keyword}.*",
      Regex::Options::IGNORE_CASE
    )

    # Find first match with US pattern
    found = all_zones.find { |zone| us_pattern.matches?(zone) }

    # If not found, try global pattern
    found ||= all_zones.find { |zone| global_pattern.matches?(zone) }

    if found
      @@logger.try &.info { "Fuzzy matched '#{keyword}' → '#{found}'" }
    else
      @@logger.try &.info { "No timezone match found for '#{keyword}'" }
      return nil
    end

    begin
      Time::Location.load(found)
    rescue
      nil
    end
  end
end
