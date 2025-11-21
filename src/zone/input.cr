require "./timestamp_patterns"

module Zone
  class Input
    @source : Array(String)?

    def initialize(@argv : Array(String), @stdin : IO = STDIN)
      @skip_first = false
    end

    def each_line(&block : String -> _)
      source.each(&block)
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
      source.first?
    end

    private def source : Array(String)
      @source ||= begin
        if @argv.any?
          # Arguments provided - use them as timestamps
          @argv
        elsif !@stdin.tty?
          # No arguments but stdin is piped - read from stdin
          # Convert to array so it can be iterated multiple times (e.g., for headers)
          @stdin.each_line.map(&.chomp).to_a
        else
          # Interactive mode with no arguments - use current time
          [Time.local.to_s]
        end
      end
    end
  end
end
