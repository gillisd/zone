require "log"
require "./colors"

module Zone
  module Logging
    extend self

    def build(verbose : Bool) : Log
      # Configure log backend to stderr
      backend = Log::IOBackend.new(STDERR)
      backend.formatter = Log::Formatter.new do |entry, io|
        prefix, color = log_style(entry.severity)
        formatted = "#{prefix} #{entry.message}"
        colored = case color
        when :cyan
          Colors.colors(STDERR).cyan(formatted)
        when :yellow
          Colors.colors(STDERR).yellow(formatted)
        when :red
          Colors.colors(STDERR).red(formatted)
        else
          formatted
        end
        io << colored
      end

      logger = Log.for("zone")
      logger.backend = backend
      logger.level = verbose ? Log::Severity::Debug : Log::Severity::Warn
      logger
    end

    private def log_style(severity : Log::Severity)
      case severity
      when Log::Severity::Info
        {"→", :cyan}
      when Log::Severity::Warn
        {"⚠", :yellow}
      when Log::Severity::Error
        {"✗", :red}
      when Log::Severity::Debug
        {"DEBUG", nil}
      else
        {"?", nil}
      end
    end
  end
end
