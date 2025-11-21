require "./colors"

module Zone
  class Output
    def initialize(color_mode : String = "auto", @stream : IO = STDOUT)
      @colors = colorize(color_mode)
    end

    def puts(text : String)
      @stream.puts(text)
    end

    def puts_highlighted(text : String, highlight : String)
      highlight_str = highlight.to_s
      output = text.sub(highlight_str, @colors.cyan(highlight_str))
      @stream.puts(output)
    end

    def colorize_timestamp(timestamp : String | Int64) : String
      @colors.cyan(timestamp.to_s)
    end

    private def colorize(mode : String)
      case mode
      when "always"
        Colors::ANSI
      when "never"
        Colors::PlainText
      when "auto"
        Colors.colors(@stream)
      else
        Colors.colors(@stream)
      end
    end
  end
end
