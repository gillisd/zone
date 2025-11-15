module Zone
  # Maps timezone identifiers to their standard abbreviations
  # This is needed because Crystal's Time API doesn't expose zone abbreviations
  module TimezoneAbbreviations
    ABBREVIATIONS = {
      # Major world cities
      "Asia/Tokyo" => "JST",
      "Asia/Shanghai" => "CST",
      "Asia/Hong_Kong" => "HKT",
      "Asia/Singapore" => "SGT",
      "Asia/Seoul" => "KST",
      "Asia/Dubai" => "GST",
      "Asia/Kolkata" => "IST",
      "Asia/Jakarta" => "WIB",

      # Americas
      "America/New_York" => "EST",  # Standard time
      "America/Chicago" => "CST",
      "America/Denver" => "MST",
      "America/Los_Angeles" => "PST",
      "America/Phoenix" => "MST",
      "America/Anchorage" => "AKST",
      "Pacific/Honolulu" => "HST",
      "America/Toronto" => "EST",
      "America/Montreal" => "EST",
      "America/Vancouver" => "PST",
      "America/Mexico_City" => "CST",
      "America/Sao_Paulo" => "BRT",
      "America/Buenos_Aires" => "ART",
      "America/Santiago" => "CLT",
      "America/Bogota" => "COT",
      "America/Lima" => "PET",
      "America/Caracas" => "VET",

      # Europe
      "Europe/London" => "GMT",
      "Europe/Paris" => "CET",
      "Europe/Berlin" => "CET",
      "Europe/Madrid" => "CET",
      "Europe/Rome" => "CET",
      "Europe/Amsterdam" => "CET",
      "Europe/Brussels" => "CET",
      "Europe/Vienna" => "CET",
      "Europe/Zurich" => "CET",
      "Europe/Stockholm" => "CET",
      "Europe/Oslo" => "CET",
      "Europe/Copenhagen" => "CET",
      "Europe/Helsinki" => "EET",
      "Europe/Athens" => "EET",
      "Europe/Istanbul" => "TRT",
      "Europe/Moscow" => "MSK",
      "Europe/Kyiv" => "EET",
      "Europe/Warsaw" => "CET",
      "Europe/Prague" => "CET",
      "Europe/Budapest" => "CET",
      "Europe/Bucharest" => "EET",
      "Europe/Sofia" => "EET",
      "Europe/Dublin" => "IST",
      "Europe/Lisbon" => "WET",

      # Australia & Pacific
      "Australia/Sydney" => "AEDT",
      "Australia/Melbourne" => "AEDT",
      "Australia/Brisbane" => "AEST",
      "Australia/Perth" => "AWST",
      "Australia/Adelaide" => "ACDT",
      "Australia/Darwin" => "ACST",
      "Pacific/Auckland" => "NZDT",
      "Pacific/Fiji" => "FJT",

      # Africa & Middle East
      "Africa/Cairo" => "EET",
      "Africa/Johannesburg" => "SAST",
      "Africa/Nairobi" => "EAT",
      "Africa/Lagos" => "WAT",
      "Africa/Casablanca" => "WET",

      # Special zones
      "UTC" => "UTC",
      "GMT" => "GMT",
      "Local" => "Local",
    }

    def self.get(zone_name : String) : String
      ABBREVIATIONS[zone_name]? || zone_name
    end

    # Get abbreviation for a Time object based on its location
    def self.get_for_time(time : Time) : String
      location_name = time.location.name
      get(location_name)
    end
  end
end
