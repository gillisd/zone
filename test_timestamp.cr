require "./src/zone"

puts "Testing Timestamp.parse..."
begin
  ts = Zone::Timestamp.parse("2025-01-15T10:30:00Z")
  puts "Parsed timestamp: #{ts.time}"
  puts "to_iso8601: #{ts.to_iso8601}"
  puts "to_unix: #{ts.to_unix}"
  puts "to_pretty: #{ts.to_pretty}"
rescue ex
  puts "Error: #{ex.message}"
  puts ex.backtrace.join("\n")
end
