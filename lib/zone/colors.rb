# frozen_string_literal: true

# Extracted from command_kit gem (https://github.com/postmodern/command_kit.rb)
# Copyright (c) 2021-2024 Hal Brodigan
# Licensed under the MIT License
#
# This is a simplified version containing only the ANSI module for use in
# error messages. The full command_kit gem provides many additional features.

module Zone
  #
  # ANSI color codes for terminal output.
  #
  # @see https://en.wikipedia.org/wiki/ANSI_escape_code
  #
  module Colors
    # ANSI reset code
    RESET = "\e[0m"

    # ANSI color code for red text
    RED = "\e[31m"

    # ANSI color code for yellow text
    YELLOW = "\e[33m"

    # ANSI color code for green text
    GREEN = "\e[32m"

    # ANSI color code for cyan text
    CYAN = "\e[36m"

    # ANSI color code for bright/bold text
    BOLD = "\e[1m"

    module_function

    #
    # Wraps text in red color codes.
    #
    # @param [String] text
    #   The text to colorize
    #
    # @return [String]
    #   The red colorized text with reset
    #
    def red(text)
      "#{RED}#{text}#{RESET}"
    end

    #
    # Wraps text in yellow color codes.
    #
    # @param [String] text
    #   The text to colorize
    #
    # @return [String]
    #   The yellow colorized text with reset
    #
    def yellow(text)
      "#{YELLOW}#{text}#{RESET}"
    end

    #
    # Wraps text in green color codes.
    #
    # @param [String] text
    #   The text to colorize
    #
    # @return [String]
    #   The green colorized text with reset
    #
    def green(text)
      "#{GREEN}#{text}#{RESET}"
    end

    #
    # Wraps text in cyan color codes.
    #
    # @param [String] text
    #   The text to colorize
    #
    # @return [String]
    #   The cyan colorized text with reset
    #
    def cyan(text)
      "#{CYAN}#{text}#{RESET}"
    end

    #
    # Wraps text in bold codes.
    #
    # @param [String] text
    #   The text to make bold
    #
    # @return [String]
    #   The bold text with reset
    #
    def bold(text)
      "#{BOLD}#{text}#{RESET}"
    end

    #
    # Checks if the stream supports ANSI colors.
    #
    # @param [IO] stream
    #   The stream to check (default: $stderr)
    #
    # @return [Boolean]
    #   true if colors should be used, false otherwise
    #
    # @note
    #   When TERM=dumb or NO_COLOR env var is set, returns false.
    #   Also returns false if stream is not a TTY.
    #
    def enabled?(stream = $stderr)
      ENV['TERM'] != 'dumb' && !ENV['NO_COLOR'] && stream.tty?
    end

    #
    # Colorizes text only if colors are enabled for the stream.
    #
    # @param [String] text
    #   The text to potentially colorize
    #
    # @param [Symbol] color
    #   The color method to use (:red, :yellow, :green, :cyan, :bold)
    #
    # @param [IO] stream
    #   The stream to check for color support (default: $stderr)
    #
    # @return [String]
    #   Colorized text if colors enabled, plain text otherwise
    #
    def wrap(text, color, stream = $stderr)
      if enabled?(stream)
        send(color, text)
      else
        text
      end
    end
  end
end
