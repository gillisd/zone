# frozen_string_literal: true

require_relative 'options'
require_relative 'input'
require_relative 'output'
require_relative 'transform'
require_relative 'colors'
require_relative 'logging'
require_relative 'pattern'
require_relative 'field'

module Zone
  class CLI
    def self.run(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv
    end

    def run
      options = Options.new
      options.parse!(@argv)
      options.validate!

      setup_logger!(options.verbose)
      setup_active_support!

      input = Input.new(@argv)
      output = Output.new(color_mode: options.color)
      transformation = Transform.build(zone: options.zone, format: options.format)

      if options.field
        Field.process(input, output, transformation, options, @logger)
      else
        Pattern.process(input, output, transformation, @logger)
      end
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption, OptionParser::InvalidArgument => e
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{e.message}"
      $stderr.puts "Run 'zone --help' for usage information."
      exit 1
    rescue ArgumentError, StandardError => e
      message = e.message.gsub(/'([^']+)'/) do
        "'#{Colors.colors($stderr).bold($1)}'"
      end
      $stderr.puts Colors.colors($stderr).red("Error:") + " #{message}"
      exit 1
    end

    private

    def setup_logger!(verbose)
      @logger = Logging.build(verbose: verbose)
    end

    def setup_active_support!
      if defined?(ActiveSupport)
        ActiveSupport.to_time_preserves_timezone = true
      end
    end

  end
end
