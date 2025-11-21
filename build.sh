#!/bin/bash
# Build script for Zone Crystal implementation

set -e

echo "Building Zone..."

# Check if Crystal is installed
if ! command -v crystal &> /dev/null; then
    echo "Error: Crystal is not installed"
    echo "Please install Crystal from https://crystal-lang.org/install/"
    exit 1
fi

# Create bin directory
mkdir -p bin

# Build the executable
echo "Compiling src/cli.cr..."
crystal build src/cli.cr --release -o bin/zone

echo "Build complete! Executable is at: bin/zone"
echo ""
echo "To install system-wide, run:"
echo "  sudo cp bin/zone /usr/local/bin/"
echo ""
echo "To run tests:"
echo "  crystal spec"
