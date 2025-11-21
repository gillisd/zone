require "./zone/version"
require "./zone/field_mapping"
require "./zone/field_line"
require "./zone/timestamp"
require "./zone/cli"

module Zone
  class Error < Exception; end

  def self.find(keyword : String) : Time::Location?
    # Try exact match first
    begin
      return Time::Location.load(keyword)
    rescue
      # Fall through to fuzzy search
    end

    search_fuzzy(keyword)
  end

  private def self.search_fuzzy(keyword : String) : Time::Location?
    all_zones = Time::Location.available_timezones

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

    return nil unless found

    begin
      Time::Location.load(found)
    rescue
      nil
    end
  end
end
