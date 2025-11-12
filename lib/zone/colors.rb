# frozen_string_literal: true

# Extracted from command_kit gem (https://github.com/postmodern/command_kit.rb)
# Copyright (c) 2021-2024 Hal Brodigan
# Licensed under the MIT License
#
# This is a simplified version containing only the ANSI color functionality.
# The full command_kit gem provides many additional features.

module Zone
  #
  # ANSI color codes for terminal output.
  #
  # @see https://en.wikipedia.org/wiki/ANSI_escape_code
  #
  module Colors
    #
    # Applies ANSI formatting to text.
    #
    module ANSI
      # ANSI reset code
      RESET = "\e[0m"

      # ANSI code for bold text
      BOLD = "\e[1m"

      # ANSI code to disable boldness
      RESET_INTENSITY = "\e[22m"

      # ANSI color code for red text
      RED = "\e[31m"

      # ANSI color code for yellow text
      YELLOW = "\e[33m"

      # ANSI color code for green text
      GREEN = "\e[32m"

      # ANSI color code for cyan text
      CYAN = "\e[36m"

      # ANSI color for the default foreground color
      RESET_FG = "\e[39m"

      module_function

      #
      # Bolds the text.
      #
      # @param [String, nil] string
      #   An optional string.
      #
      # @return [String, BOLD]
      #   The bolded string or just {BOLD} if no arguments were given.
      #
      def bold(string=nil)
        if string then "#{BOLD}#{string}#{RESET_INTENSITY}"
        else           BOLD
        end
      end

      #
      # Sets the text color to red.
      #
      # @param [String, nil] string
      #   An optional string.
      #
      # @return [String, RED]
      #   The colorized string or just {RED} if no arguments were given.
      #
      def red(string=nil)
        if string then "#{RED}#{string}#{RESET_FG}"
        else           RED
        end
      end

      #
      # Sets the text color to yellow.
      #
      # @param [String, nil] string
      #   An optional string.
      #
      # @return [String, YELLOW]
      #   The colorized string or just {YELLOW} if no arguments were given.
      #
      def yellow(string=nil)
        if string then "#{YELLOW}#{string}#{RESET_FG}"
        else           YELLOW
        end
      end

      #
      # Sets the text color to green.
      #
      # @param [String, nil] string
      #   An optional string.
      #
      # @return [String, GREEN]
      #   The colorized string or just {GREEN} if no arguments were given.
      #
      def green(string=nil)
        if string then "#{GREEN}#{string}#{RESET_FG}"
        else           GREEN
        end
      end

      #
      # Sets the text color to cyan.
      #
      # @param [String, nil] string
      #   An optional string.
      #
      # @return [String, CYAN]
      #   The colorized string or just {CYAN} if no arguments were given.
      #
      def cyan(string=nil)
        if string then "#{CYAN}#{string}#{RESET_FG}"
        else           CYAN
        end
      end
    end

    #
    # Dummy module with the same interface as {ANSI}, but for when ANSI is not
    # supported.
    #
    module PlainText
      ANSI.constants(false).each do |name|
        const_set(name,'')
      end

      module_function

      [:bold, :red, :yellow, :green, :cyan].each do |name|
        define_method(name) do |string=nil|
          string || ''
        end
      end
    end

    module_function

    #
    # Checks if the stream supports ANSI output.
    #
    # @param [IO] stream
    #
    # @return [Boolean]
    #
    # @note
    #   When the env variable `TERM` is set to `dumb` or when the `NO_COLOR`
    #   env variable is set, it will disable color output. Color output will
    #   also be disabled if the given stream is not a TTY.
    #
    def ansi?(stream=$stdout)
      ENV['TERM'] != 'dumb' && !ENV['NO_COLOR'] && stream.tty?
    end

    #
    # Returns the colors available for the given stream.
    #
    # @param [IO] stream
    #
    # @return [ANSI, PlainText]
    #   The ANSI module or PlainText dummy module.
    #
    # @example
    #   puts colors.green("Hello world")
    #
    # @example Using colors with stderr output:
    #   stderr.puts colors(stderr).green("Hello world")
    #
    def colors(stream=$stdout)
      if ansi?(stream) then ANSI
      else                  PlainText
      end
    end
  end
end
