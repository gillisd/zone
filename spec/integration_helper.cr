require "./spec_helper"
require "process"
require "file_utils"

def zone_bin : String
  File.expand_path("../bin/zone", __DIR__)
end

def run_zone(*args : String) : Tuple(String, Int32)
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run(
    zone_bin,
    args: args.to_a,
    output: output,
    error: error
  )
  combined = output.to_s + error.to_s
  {combined, status.exit_code}
end

def run_zone_with_input(input : String, *args : String) : Tuple(String, Int32)
  output = IO::Memory.new
  error = IO::Memory.new
  process = Process.new(
    zone_bin,
    args: args.to_a,
    input: Process::Redirect::Pipe,
    output: output,
    error: error
  )
  process.input.print(input)
  process.input.close
  status = process.wait
  combined = output.to_s + error.to_s
  {combined, status.exit_code}
end
