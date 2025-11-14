# frozen_string_literal: true

require_relative 'timestamp_patterns'

module Zone
  class Input
    def initialize(argv, stdin: $stdin)
      @argv = argv
      @stdin = stdin
    end

    def each_line(&block)
      source.each(&block)
    end

    def skip_headers?
      @skip_first ||= false
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

    def from_arguments?
      @argv.any?
    end

    private

    def source
      @source ||= begin
        if @argv.any?
          # Arguments provided - use them as timestamps
          @argv
        elsif !@stdin.tty?
          # No arguments but stdin is piped - read from stdin
          @stdin.each_line(chomp: true)
        else
          # Interactive mode with no arguments - use current time
          [Time.now.to_s]
        end
      end
    end
  end
end
