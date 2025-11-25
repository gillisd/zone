require "./timestamp_patterns"

module Zone
  class Input
    @first_line : String?
    @first_line_read : Bool = false
    @tty_timestamp : String?

    def initialize(@argv : Array(String), @stdin : IO = STDIN)
      @skip_first = false
    end

    def each_line(&block : String -> _)
      if @argv.any?
        # Arguments provided - iterate over them directly
        @argv.each(&block)
      elsif !@stdin.tty?
        # Stdin is piped - stream lines
        stream_stdin_lines(&block)
      else
        # Interactive mode - yield cached current time
        yield tty_timestamp
      end
    end

    def skip_headers? : Bool
      if @skip_first
        @skip_first = false
        true
      else
        false
      end
    end

    def mark_skip_headers!
      @skip_first = true
    end

    def from_arguments? : Bool
      @argv.any?
    end

    def first_line? : String?
      if @argv.any?
        @argv.first?
      elsif !@stdin.tty?
        read_first_line_from_stdin
      else
        tty_timestamp
      end
    end

    private def tty_timestamp : String
      @tty_timestamp ||= Time.local.to_s
    end

    private def read_first_line_from_stdin : String?
      return @first_line if @first_line_read

      @first_line_read = true
      if line = @stdin.gets
        @first_line = line.chomp
      else
        @first_line = nil
      end
      @first_line
    end

    private def stream_stdin_lines(&block : String -> _)
      # If first_line was already read, yield it first
      if @first_line_read && @first_line
        yield @first_line.not_nil!
      end

      # Stream remaining lines directly from stdin
      # If first_line wasn't read yet, this streams all lines
      # If first_line was read, this streams the rest
      @stdin.each_line do |line|
        yield line.chomp
      end
    end
  end
end
