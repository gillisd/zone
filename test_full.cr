require "./src/zone"

puts "Testing full CLI flow..."

transformation = Zone::Transform.build(zone: "local", format: {pretty: 1})
result = transformation.call("2025-01-15T10:30:00Z")
puts "Transformation result: #{result.inspect}"

puts "\nTesting pattern matching..."
line = "2025-01-15T10:30:00Z"
output = Zone::Output.new
input = Zone::Input.new([line])

logger = Zone::Logging.build(verbose: true)

puts "\nRunning Pattern.process..."
Zone::Pattern.process(input, output, transformation, logger)
puts "\nDone"
