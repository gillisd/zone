require "./colors"

module Zone
  class Output
    @stream : IO
    @use_colors : Bool

    def initialize(color_mode : String = "auto", stream : IO = STDOUT)
      @stream = stream
      @use_colors = should_colorize(color_mode, stream)
    end

    def puts(text : String)
      @stream.puts(text)
    end

    def puts_highlighted(text : String, highlight : String | Int32)
      highlight_str = highlight.to_s
      output = if @use_colors
        text.sub(highlight_str, Colors::ANSI.cyan(highlight_str))
      else
        text
      end
      @stream.puts(output)
    end

    def colorize_timestamp(timestamp : String) : String
      @use_colors ? Colors::ANSI.cyan(timestamp) : timestamp
    end

    private def should_colorize(mode : String, stream : IO) : Bool
      case mode
      when "always"
        true
      when "never"
        false
      when "auto"
        Colors.ansi?(stream)
      else
        false
      end
    end
  end
end
