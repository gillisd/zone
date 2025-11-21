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

      #
      # Bolds the text.
      #
      def self.bold(string : String? = nil) : String
        if string
          "#{BOLD}#{string}#{RESET_INTENSITY}"
        else
          BOLD
        end
      end

      #
      # Sets the text color to red.
      #
      def self.red(string : String? = nil) : String
        if string
          "#{RED}#{string}#{RESET_FG}"
        else
          RED
        end
      end

      #
      # Sets the text color to yellow.
      #
      def self.yellow(string : String? = nil) : String
        if string
          "#{YELLOW}#{string}#{RESET_FG}"
        else
          YELLOW
        end
      end

      #
      # Sets the text color to green.
      #
      def self.green(string : String? = nil) : String
        if string
          "#{GREEN}#{string}#{RESET_FG}"
        else
          GREEN
        end
      end

      #
      # Sets the text color to cyan.
      #
      def self.cyan(string : String? = nil) : String
        if string
          "#{CYAN}#{string}#{RESET_FG}"
        else
          CYAN
        end
      end
    end

    #
    # Dummy module with the same interface as ANSI, but for when ANSI is not
    # supported.
    #
    module PlainText
      RESET           = ""
      BOLD            = ""
      RESET_INTENSITY = ""
      RED             = ""
      YELLOW          = ""
      GREEN           = ""
      CYAN            = ""
      RESET_FG        = ""

      def self.bold(string : String? = nil) : String
        string || ""
      end

      def self.red(string : String? = nil) : String
        string || ""
      end

      def self.yellow(string : String? = nil) : String
        string || ""
      end

      def self.green(string : String? = nil) : String
        string || ""
      end

      def self.cyan(string : String? = nil) : String
        string || ""
      end
    end

    #
    # Checks if the stream supports ANSI output.
    #
    # @note
    #   When the env variable `TERM` is set to `dumb` or when the `NO_COLOR`
    #   env variable is set, it will disable color output. Color output will
    #   also be disabled if the given stream is not a TTY.
    #
    def self.ansi?(stream : IO = STDOUT) : Bool
      ENV["TERM"]? != "dumb" && !ENV.has_key?("NO_COLOR") && stream.tty?
    end

    #
    # Returns the colors available for the given stream.
    #
    def self.colors(stream : IO = STDOUT)
      if ansi?(stream)
        ANSI
      else
        PlainText
      end
    end
  end
end
