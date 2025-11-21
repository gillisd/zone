require "./options"
require "./input"
require "./output"
require "./transform"
require "./colors"
require "./logging"
require "./pattern"
require "./field"

module Zone
  class CLI
    def self.run(argv : Array(String))
      new(argv).run
    end

    def initialize(@argv : Array(String))
    end

    def run
      options = Options.new
      options.parse!(@argv)
      options.validate!

      logger = setup_logger!(options.verbose, options.silent)

      input = Input.new(@argv)
      output = Output.new(color_mode: options.color)
      transformation = Transform.build(zone: options.zone, format: options.format)

      if options.field
        Field.process(input, output, transformation, options, logger)
      else
        Pattern.process(input, output, transformation, logger)
      end
    rescue ex : OptionParser::Exception | ArgumentError
      message = ex.message.to_s.gsub(/'([^']+)'/) do
        "'#{Colors.colors(STDERR).bold($1)}'"
      end
      STDERR.puts Colors.colors(STDERR).red("Error:") + " #{message}"
      exit 1
    rescue ex : Exception
      message = ex.message.to_s.gsub(/'([^']+)'/) do
        "'#{Colors.colors(STDERR).bold($1)}'"
      end
      STDERR.puts Colors.colors(STDERR).red("Error:") + " #{message}"
      exit 1
    end

    private def setup_logger!(verbose : Bool, silent : Bool) : Log
      Logging.build(verbose: verbose, silent: silent)
    end
  end
end
