require "./src/zone"

puts "=== DEBUG OUTPUT ==="
puts "ARGV: #{ARGV.inspect}"
puts "Starting CLI..."
puts ""

begin
  Zone::CLI.run(ARGV)
  puts ""
  puts "=== CLI COMPLETED ==="
rescue ex
  puts "ERROR: #{ex.class}: #{ex.message}"
  puts ex.backtrace.join("\n")
end
