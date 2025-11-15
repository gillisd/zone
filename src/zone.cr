require "tzinfo"
require "./zone/version"
require "./zone/field_mapping"
require "./zone/field_line"
require "./zone/timestamp"
require "./zone/cli"

module Zone
  class Error < Exception; end

  def self.find(keyword : String)
    TZInfo::Timezone.get(keyword)
  rescue TZInfo::InvalidTimezoneIdentifier
    search_fuzzy(keyword)
  end

  private def self.search_fuzzy(keyword : String)
    all_zones = TZInfo::Timezone.all_identifiers

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

    # Find matching zone
    found = all_zones.find { |z| z =~ us_pattern } || all_zones.find { |z| z =~ global_pattern }

    return nil unless found

    TZInfo::Timezone.get(found)
  end
end
