# frozen_string_literal: true

require 'tzinfo'
require_relative "zone/version"
require_relative "zone/field_mapping"
require_relative "zone/field_line"
require_relative "zone/timestamp"
require_relative "zone/cli"

module Zone
  class Error < StandardError; end

  def self.find(keyword)
    TZInfo::Timezone.get(keyword)
  rescue TZInfo::InvalidTimezoneIdentifier
    search_fuzzy(keyword)
  end

  def self.search_fuzzy(keyword)
    all_zones = TZInfo::Timezone.all_identifiers

    # Normalize keyword: replace spaces with wildcards for matching
    normalized_keyword = keyword.gsub(/\s+/, '.*')

    # Try US wildcard pattern first
    us_pattern = Regexp.new(
      normalized_keyword.gsub(/^(?:US)?\/?/, 'US/').gsub(/$/,'.*'),
      Regexp::IGNORECASE
    )

    # Then try global pattern
    global_pattern = Regexp.new(
      ".*#{normalized_keyword}.*",
      Regexp::IGNORECASE
    )

    found = case all_zones
    in [*, ^(us_pattern) => zone, *]
      zone
    in [*, ^(global_pattern) => zone, *]
      zone
    else
      nil
    end

    return nil unless found

    TZInfo::Timezone.get(found)
  end

  private_class_method :search_fuzzy
end
