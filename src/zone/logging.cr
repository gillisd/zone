require "log"
require "./colors"

module Zone
  module Logging
    extend self

    def build(verbose : Bool) : Log
      logger = Log.for("zone")
      logger.level = verbose ? Log::Severity::Debug : Log::Severity::Warn
      logger
    end

    private def formatter
      ->(severity : String, _datetime : Time, _progname : String, message : String) {
        prefix, color = log_style(severity)
        formatted = "#{prefix} #{message}"
        colored = color ? Colors.colors(STDERR).send(color, formatted) : formatted
        "#{colored}\n"
      }
    end

    private def log_style(severity : String)
      case severity
      when "INFO"
        {"→", :cyan}
      when "WARN"
        {"⚠", :yellow}
      when "ERROR"
        {"✗", :red}
      when "DEBUG"
        {"DEBUG:", nil}
      else
        {"?", nil}
      end
    end
  end
end
