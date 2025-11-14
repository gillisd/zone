# frozen_string_literal: true

require 'logger'
require_relative 'colors'

module Zone
  module Logging
    module_function

    def build(verbose:)
      Logger.new($stderr).tap do |l|
        l.formatter = formatter
        l.level = verbose ? Logger::DEBUG : Logger::WARN
      end
    end

    def formatter
      ->(severity, _datetime, _progname, message) {
        prefix, color = log_style(severity)
        formatted = "#{prefix} #{message}"
        colored = color ? Colors.colors($stderr).send(color, formatted) : formatted
        "#{colored}\n"
      }
    end
    private_class_method :formatter

    def log_style(severity)
      case severity
      in "INFO"  then ["→", :cyan]
      in "WARN"  then ["⚠", :yellow]
      in "ERROR" then ["✗", :red]
      in "DEBUG" then ["DEBUG:", nil]
      else ["?", nil]
      end
    end
    private_class_method :log_style
  end
end
