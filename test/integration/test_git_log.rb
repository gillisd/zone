# frozen_string_literal: true

require "test_helper"

class TestGitLogIntegration < Minitest::Test
  parallelize_me!

  def setup
    @zone_bin = File.expand_path("../../exe/zone", __dir__)
  end

  def run_zone_with_input(input, *args)
    escaped_args = args.map { |arg| "'#{arg}'" }.join(" ")
    output = `echo "#{input}" | #{@zone_bin} #{escaped_args} 2>&1`
    [output.force_encoding('UTF-8'), $?.exitstatus]
  end

  def test_git_log_default_format
    input = <<~GIT
      commit 10c4dee32ff403b39681f9d1cc3ae51885c999fc
      Author: Claude <noreply@anthropic.com>
      Date:   Fri Nov 14 23:56:21 2025 +0000

          Add git log timestamp pattern support
    GIT

    output, status = run_zone_with_input(input, "--zone", "Tokyo")

    assert_equal 0, status
    assert_match(/Nov 15, 2025/, output)  # Converted to Tokyo timezone (next day)
    assert_match(/8:56 AM JST/, output)   # 23:56 UTC = 08:56 JST next day
    assert_match(/commit 10c4dee/, output)  # Non-timestamp lines preserved
  end

  def test_git_log_with_negative_offset
    input = "Date:   Fri Nov 14 14:54:35 2025 -0500"

    output, status = run_zone_with_input(input, "--zone", "UTC")

    assert_equal 0, status
    assert_match(/Nov 14, 2025/, output)
    assert_match(/7:54 PM UTC/, output)  # -0500 + 5 hours = UTC
  end

  def test_git_log_with_single_digit_day
    input = "Date:   Wed Nov 5 11:24:19 2025 -0500"

    output, status = run_zone_with_input(input, "--zone", "EST")

    assert_equal 0, status
    assert_match(/Nov 0?5, 2025/, output)  # May have leading zero
    assert_match(/11:24 AM EST/, output)
  end

  def test_git_log_fuller_format
    input = <<~GIT
      commit 054d8f9baa21268e2cec66e8e265580fc31f6b7e
      Author:     Claude <noreply@anthropic.com>
      AuthorDate: Fri Nov 14 23:48:24 2025 +0000
      Commit:     Claude <noreply@anthropic.com>
      CommitDate: Fri Nov 14 23:48:24 2025 +0000
    GIT

    output, status = run_zone_with_input(input, "--zone", "PST")

    assert_equal 0, status
    # Both timestamps should be converted
    assert_match(/AuthorDate:.*Nov 14, 2025.*3:48 PM PST/, output)
    assert_match(/CommitDate:.*Nov 14, 2025.*3:48 PM PST/, output)
  end

  def test_git_log_passes_through_non_timestamp_lines
    input = <<~GIT
      commit abc123
      Author: Test User <test@example.com>
      Date:   Fri Nov 14 10:00:00 2025 +0000

          This is a commit message
          with multiple lines
    GIT

    output, status = run_zone_with_input(input, "--zone", "UTC")

    assert_equal 0, status
    assert_match(/commit abc123/, output)
    assert_match(/Author: Test User/, output)
    assert_match(/This is a commit message/, output)
    assert_match(/with multiple lines/, output)
  end

  def test_git_log_with_multiple_commits
    input = <<~GIT
      Date:   Fri Nov 14 23:00:00 2025 +0000

      commit 2
      Date:   Fri Nov 14 22:00:00 2025 +0000

      commit 3
      Date:   Fri Nov 14 21:00:00 2025 +0000
    GIT

    output, status = run_zone_with_input(input, "--zone", "EST")

    assert_equal 0, status
    lines = output.lines

    # All three timestamps should be converted
    assert_match(/6:00 PM EST/, lines[0])  # 23:00 UTC = 18:00 EST
    assert_match(/5:00 PM EST/, lines[3])  # 22:00 UTC = 17:00 EST
    assert_match(/4:00 PM EST/, lines[6])  # 21:00 UTC = 16:00 EST
  end

  def test_git_log_does_not_corrupt_commit_hashes
    # Commit hash 18cb3e41e88aa1ebe1785815368ac12500a818e8 contains "1785815368"
    # which is a valid unix timestamp (Aug 03, 2026). The hash should NOT be converted
    # because it's part of a hexadecimal string.
    input = <<~GIT
      commit 18cb3e41e88aa1ebe1785815368ac12500a818e8
      Author: Test User <test@example.com>
      Date:   Fri Nov 14 10:00:00 2025 +0000

          Fix handling of timestamps in git logs
    GIT

    output, status = run_zone_with_input(input, "--zone", "EST")

    assert_equal 0, status
    # Commit hash should remain intact (not corrupted by timestamp conversion)
    assert_match(/commit 18cb3e41e88aa1ebe1785815368ac12500a818e8/, output)
    # Date line should still be converted
    assert_match(/Nov 14, 2025/, output)
    assert_match(/5:00 AM EST/, output)
  end
end
