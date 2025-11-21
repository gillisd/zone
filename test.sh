#!/bin/bash
# Test script for Zone Crystal implementation

set -e

echo "Running Zone test suite..."

# Check if Crystal is installed
if ! command -v crystal &> /dev/null; then
    echo "Error: Crystal is not installed"
    echo "Please install Crystal from https://crystal-lang.org/install/"
    exit 1
fi

# Run unit tests
echo "Running unit tests..."
crystal spec --verbose

echo ""
echo "All tests passed!"
