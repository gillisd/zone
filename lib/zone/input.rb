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

    private

    def source
      @source ||= begin
        if timestamps_from_arguments?
          @argv
        elsif @argv.any? || !@stdin.tty?
          @stdin.each_line(chomp: true)
        else
          [Time.now.to_s]
        end
      end
    end

    def timestamps_from_arguments?
      @argv.any? && @argv.all? { |arg| TimestampPatterns.match?(arg) }
    end
  end
end
