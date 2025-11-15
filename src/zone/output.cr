require "./colors"

module Zone
  class Output
    @stream : IO
    @colors : (typeof(Colors::ANSI) | typeof(Colors::PlainText))

    def initialize(color_mode : String = "auto", stream : IO = STDOUT)
      @stream = stream
      @colors = colorize(color_mode)
    end

    def puts(text : String)
      @stream.puts(text)
    end

    def puts_highlighted(text : String, highlight : String | Int32)
      highlight_str = highlight.to_s
      output = text.sub(highlight_str, @colors.cyan(highlight_str))
      @stream.puts(output)
    end

    def colorize_timestamp(timestamp : String)
      @colors.cyan(timestamp)
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
        Colors::PlainText
      end
    end
  end
end
