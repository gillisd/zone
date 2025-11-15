require "./zone/version"
require "./zone/field_mapping"
require "./zone/field_line"
require "./zone/timestamp"
require "./zone/cli"

module Zone
  class Error < Exception; end

  TIMEZONE_MAPPINGS = {
    "tokyo" => "Asia/Tokyo",
    "pacific" => "America/Los_Angeles",
    "mountain" => "America/Denver",
    "central" => "America/Chicago",
    "eastern" => "America/New_York",
    "utc" => "UTC",
    "gmt" => "GMT",
    "est" => "America/New_York",
    "pst" => "America/Los_Angeles",
    "cst" => "America/Chicago",
    "mst" => "America/Denver",
  }

  def self.find(keyword : String) : Time::Location?
    # Try direct lookup
    begin
      return Time::Location.load(keyword)
    rescue
    end

    # Try normalized lookup
    normalized = keyword.downcase.gsub(/\s+/, "_")
    if mapped = TIMEZONE_MAPPINGS[normalized]?
      begin
        return Time::Location.load(mapped)
      rescue
      end
    end

    # Try fuzzy search
    search_fuzzy(keyword)
  end

  private def self.search_fuzzy(keyword : String) : Time::Location?
    # Normalize keyword: replace spaces with wildcards for matching
    normalized_keyword = keyword.gsub(/\s+/, ".*")

    # Try US wildcard pattern first
    us_pattern = Regex.new(
      normalized_keyword.gsub(/^(?:US)?\/?/, "US/").gsub(/$/, ".*"),
      Regex::Options::IGNORE_CASE
    )

    # Then try global pattern
    global_pattern = Regex.new(
      ".*#{normalized_keyword}.*",
      Regex::Options::IGNORE_CASE
    )

    # Search common timezone patterns
    [
      "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles",
      "America/Phoenix", "America/Anchorage", "Pacific/Honolulu",
      "Europe/London", "Europe/Paris", "Europe/Berlin", "Europe/Madrid",
      "Asia/Tokyo", "Asia/Shanghai", "Asia/Hong_Kong", "Asia/Singapore",
      "Asia/Dubai", "Asia/Kolkata", "Australia/Sydney"
    ].each do |zone_name|
      if zone_name =~ us_pattern || zone_name =~ global_pattern
        begin
          return Time::Location.load(zone_name)
        rescue
        end
      end
    end

    nil
  end
end
