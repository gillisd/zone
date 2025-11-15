# frozen_string_literal: true

require "test_helper"

class TestZone < Minitest::Test
  parallelize_me!

  def test_that_it_has_a_version_number
    refute_nil ::Zone::VERSION
  end
end
