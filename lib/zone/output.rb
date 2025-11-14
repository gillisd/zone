# frozen_string_literal: true

require_relative 'colors'

module Zone
  class Output
    def initialize(color_mode: 'auto', stream: $stdout)
      @stream = stream
      @colors = colorize(color_mode)
    end

    def puts(text)
      @stream.puts(text)
    end

    def puts_highlighted(text, highlight:)
      highlight_str = highlight.to_s
      output = text.sub(highlight_str, @colors.cyan(highlight_str))
      @stream.puts(output)
    end

    def colorize_timestamp(timestamp)
      @colors.cyan(timestamp)
    end

    private

    def colorize(mode)
      case mode
      when 'always'
        Colors::ANSI
      when 'never'
        Colors::PlainText
      when 'auto'
        Colors.colors(@stream)
      end
    end
  end
end
