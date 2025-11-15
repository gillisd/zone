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

    @argv : Array(String)
    @logger : Logger | Nil

    def initialize(@argv : Array(String))
    end

    def run
      options = Options.new
      options.parse!(@argv)
      options.validate!

      setup_logger!(options.verbose)

      input = Input.new(@argv)
      output = Output.new(color_mode: options.color)
      transformation = Transform.build(zone: options.zone, format: options.format)

      if options.field
        Field.process(input, output, transformation, options, @logger.not_nil!)
      else
        Pattern.process(input, output, transformation, @logger.not_nil!)
      end
    rescue e : OptionParser::MissingArgument | OptionParser::InvalidOption | OptionParser::InvalidArgument
      STDERR.puts Colors.colors(STDERR).red("Error:") + " #{e.message}"
      STDERR.puts "Run 'zone --help' for usage information."
      exit 1
    rescue e : ArgumentError | Exception
      message = e.message.try &.gsub(/'([^']+)'/) do |match|
        "'#{Colors.colors(STDERR).bold($1)}'"
      end || ""
      STDERR.puts Colors.colors(STDERR).red("Error:") + " #{message}"
      exit 1
    end

    private def setup_logger!(verbose : Bool)
      @logger = Logging.build(verbose: verbose)
    end
  end
end
