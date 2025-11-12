# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "zone"

require "minitest/autorun"

# Make diffs prettier
Minitest::Test.make_my_diffs_pretty!
