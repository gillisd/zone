# frozen_string_literal: true

require 'logger'
require_relative 'colors'

module Zone
  module Logging
    module_function

    #
    # Build a logger for Zone CLI.
    #
    # @param [Boolean] verbose
    #   Enable debug-level logging
    #
    # @return [Logger]
    #   Configured logger instance
    #
    def build(verbose:)
      Logger.new($stderr).tap do |l|
        l.formatter = ->(severity, _datetime, _progname, message) {
          prefix = case severity
          in "INFO"  then "→"
          in "WARN"  then "⚠"
          in "ERROR" then "✗"
          in "DEBUG" then "DEBUG:"
          else "?"
          end

          formatted = "#{prefix} #{message}"

          colored = case severity
          in "INFO"  then Colors.colors($stderr).cyan(formatted)
          in "WARN"  then Colors.colors($stderr).yellow(formatted)
          in "ERROR" then Colors.colors($stderr).red(formatted)
          else formatted
          end

          "#{colored}\n"
        }
        l.level = verbose ? Logger::DEBUG : Logger::WARN
      end
    end
  end
end
