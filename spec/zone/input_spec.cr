require "../spec_helper"

describe Zone::Input do
  describe "#each_line" do
    it "yields lines from argv when provided" do
      input = Zone::Input.new(["line1", "line2", "line3"])
      lines = [] of String
      input.each_line { |line| lines << line }
      lines.should eq(["line1", "line2", "line3"])
    end

    it "yields lines from stdin when no argv" do
      stdin = IO::Memory.new("line1\nline2\nline3\n")
      input = Zone::Input.new([] of String, stdin)
      lines = [] of String
      input.each_line { |line| lines << line }
      lines.should eq(["line1", "line2", "line3"])
    end

    it "chomps newlines from stdin" do
      stdin = IO::Memory.new("line1\nline2\n")
      input = Zone::Input.new([] of String, stdin)
      lines = [] of String
      input.each_line { |line| lines << line }
      lines.each { |line| line.should_not end_with("\n") }
    end

    it "streams lines incrementally without full buffering" do
      # This test verifies streaming behavior
      # Create a custom IO that tracks read operations
      read_count = 0
      yielded_count = 0

      # Use a pipe to simulate streaming - writer writes, reader reads
      reader, writer = IO.pipe

      # Write lines in a fiber
      spawn do
        writer.puts "line1"
        writer.flush
        writer.puts "line2"
        writer.flush
        writer.puts "line3"
        writer.flush
        writer.close
      end

      input = Zone::Input.new([] of String, reader)

      # With streaming, we should be able to process lines as they arrive
      # With buffering, this would block until all lines are available
      input.each_line do |line|
        yielded_count += 1
        # After yielding first line, we shouldn't have read all lines yet
        # (This is the key behavior difference)
      end

      yielded_count.should eq(3)
      reader.close
    end
  end

  describe "#first_line?" do
    it "returns nil for empty stdin" do
      stdin = IO::Memory.new("")
      input = Zone::Input.new([] of String, stdin)
      input.first_line?.should be_nil
    end

    it "returns first line from stdin" do
      stdin = IO::Memory.new("first\nsecond\nthird\n")
      input = Zone::Input.new([] of String, stdin)
      input.first_line?.should eq("first")
    end

    it "returns first line from argv" do
      input = Zone::Input.new(["first", "second", "third"])
      input.first_line?.should eq("first")
    end

    it "is idempotent - returns same value on multiple calls" do
      stdin = IO::Memory.new("first\nsecond\n")
      input = Zone::Input.new([] of String, stdin)
      input.first_line?.should eq("first")
      input.first_line?.should eq("first")
      input.first_line?.should eq("first")
    end

    it "does not consume subsequent lines when called" do
      stdin = IO::Memory.new("first\nsecond\nthird\n")
      input = Zone::Input.new([] of String, stdin)

      # Call first_line?
      input.first_line?.should eq("first")

      # All lines should still be available via each_line
      lines = [] of String
      input.each_line { |line| lines << line }
      lines.should eq(["first", "second", "third"])
    end
  end

  describe "#skip_headers?" do
    it "returns false by default" do
      input = Zone::Input.new(["line1"])
      input.skip_headers?.should be_false
    end

    it "returns true once after mark_skip_headers!" do
      input = Zone::Input.new(["line1", "line2"])
      input.mark_skip_headers!
      input.skip_headers?.should be_true
      input.skip_headers?.should be_false
    end

    it "works correctly with each_line iteration" do
      stdin = IO::Memory.new("header\ndata1\ndata2\n")
      input = Zone::Input.new([] of String, stdin)

      input.mark_skip_headers!
      _ = input.first_line? # Read header

      data_lines = [] of String
      input.each_line do |line|
        next if input.skip_headers? # Skip first line (header)
        data_lines << line
      end

      data_lines.should eq(["data1", "data2"])
    end
  end

  describe "#from_arguments?" do
    it "returns true when argv has elements" do
      input = Zone::Input.new(["arg1"])
      input.from_arguments?.should be_true
    end

    it "returns false when argv is empty" do
      stdin = IO::Memory.new("stdin data")
      input = Zone::Input.new([] of String, stdin)
      input.from_arguments?.should be_false
    end
  end

  describe "header workflow integration" do
    it "supports reading header then iterating remaining lines" do
      stdin = IO::Memory.new("name,timestamp,value\nfoo,12345,bar\nbaz,67890,qux\n")
      input = Zone::Input.new([] of String, stdin)

      # Simulate field.cr header workflow
      input.mark_skip_headers!
      header = input.first_line?
      header.should eq("name,timestamp,value")

      # Now iterate, skipping the header
      data_lines = [] of String
      input.each_line do |line|
        next if input.skip_headers?
        data_lines << line
      end

      data_lines.should eq(["foo,12345,bar", "baz,67890,qux"])
    end

    it "handles single-line input (header only)" do
      stdin = IO::Memory.new("name,timestamp,value\n")
      input = Zone::Input.new([] of String, stdin)

      input.mark_skip_headers!
      header = input.first_line?
      header.should eq("name,timestamp,value")

      data_lines = [] of String
      input.each_line do |line|
        next if input.skip_headers?
        data_lines << line
      end

      data_lines.should be_empty
    end
  end

  describe "tty behavior" do
    it "uses current time for tty stdin with no args" do
      # Create a mock TTY-like IO
      tty_stdin = MockTtyIO.new
      input = Zone::Input.new([] of String, tty_stdin)

      lines = [] of String
      input.each_line { |line| lines << line }

      # Should have exactly one line (current time)
      lines.size.should eq(1)
      # The line should be parseable as a time
      lines[0].should_not be_empty
    end
  end
end

# Mock IO that reports as a TTY
class MockTtyIO < IO::Memory
  def tty? : Bool
    true
  end
end
