require "log"
require "./colors"

module Zone
  module Logging
    def self.build(verbose : Int32, silent : Bool = false) : Log
      backend = Log::IOBackend.new(STDERR)
      backend.formatter = formatter

      # Silent mode suppresses all logging except errors
      # Verbose levels: 0=warn, 1+=info, 2+=debug, 3+=trace
      # Default shows warnings
      severity = if silent
        Log::Severity::Error
      elsif verbose >= 3
        Log::Severity::Trace
      elsif verbose >= 2
        Log::Severity::Debug
      elsif verbose >= 1
        Log::Severity::Info
      else
        Log::Severity::Warn
      end

      log = Log.new("zone", backend, severity)
      log
    end

    private def self.formatter : Log::Formatter
      Log::Formatter.new do |entry, io|
        prefix, color = log_style(entry.severity)
        formatted = "#{prefix} #{entry.message}"
        colored = if color
          case color
          when :cyan
            Colors.colors(STDERR).cyan(formatted)
          when :yellow
            Colors.colors(STDERR).yellow(formatted)
          when :red
            Colors.colors(STDERR).red(formatted)
          else
            formatted
          end
        else
          formatted
        end
        io << colored
      end
    end

    private def self.log_style(severity : Log::Severity) : Tuple(String, Symbol?)
      case severity
      when .info?
        {"→", :cyan}
      when .warn?
        {"⚠", :yellow}
      when .error?, .fatal?
        {"✗", :red}
      when .debug?
        {"DEBUG:", nil}
      when .trace?
        {"TRACE:", nil}
      else
        {"?", nil}
      end
    end
  end
end
