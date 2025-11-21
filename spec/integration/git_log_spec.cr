require "../integration_helper"

describe "Git Log Integration" do

  it "converts git log default format" do
    input = <<-GIT
      commit 10c4dee32ff403b39681f9d1cc3ae51885c999fc
      Author: Claude <noreply@anthropic.com>
      Date:   Fri Nov 14 23:56:21 2025 +0000

          Add git log timestamp pattern support
      GIT

    output, status = run_zone_with_input(input, "--zone", "Tokyo")

    status.should eq(0)
    output.should match(/Nov 15, 2025/)  # Converted to Tokyo timezone (next day)
    output.should match(/8:56 AM JST/)   # 23:56 UTC = 08:56 JST next day
    output.should match(/commit 10c4dee/)  # Non-timestamp lines preserved
  end

  it "converts git log with negative offset" do
    input = "Date:   Fri Nov 14 14:54:35 2025 -0500"

    output, status = run_zone_with_input(input, "--zone", "UTC")

    status.should eq(0)
    output.should match(/Nov 14, 2025/)
    output.should match(/7:54 PM UTC/)  # -0500 + 5 hours = UTC
  end

  it "converts git log with single digit day" do
    input = "Date:   Wed Nov 5 11:24:19 2025 -0500"

    output, status = run_zone_with_input(input, "--zone", "EST")

    status.should eq(0)
    output.should match(/Nov 0?5, 2025/)  # May have leading zero
    output.should match(/11:24 AM EST/)
  end

  it "converts git log fuller format" do
    input = <<-GIT
      commit 054d8f9baa21268e2cec66e8e265580fc31f6b7e
      Author:     Claude <noreply@anthropic.com>
      AuthorDate: Fri Nov 14 23:48:24 2025 +0000
      Commit:     Claude <noreply@anthropic.com>
      CommitDate: Fri Nov 14 23:48:24 2025 +0000
      GIT

    output, status = run_zone_with_input(input, "--zone", "PST")

    status.should eq(0)
    # Both timestamps should be converted
    output.should match(/AuthorDate:.*Nov 14, 2025.*3:48 PM PST/)
    output.should match(/CommitDate:.*Nov 14, 2025.*3:48 PM PST/)
  end

  it "passes through non-timestamp lines" do
    input = <<-GIT
      commit abc123
      Author: Test User <test@example.com>
      Date:   Fri Nov 14 10:00:00 2025 +0000

          This is a commit message
          with multiple lines
      GIT

    output, status = run_zone_with_input(input, "--zone", "UTC")

    status.should eq(0)
    output.should match(/commit abc123/)
    output.should match(/Author: Test User/)
    output.should match(/This is a commit message/)
    output.should match(/with multiple lines/)
  end

  it "converts multiple commits" do
    input = <<-GIT
      Date:   Fri Nov 14 23:00:00 2025 +0000

      commit 2
      Date:   Fri Nov 14 22:00:00 2025 +0000

      commit 3
      Date:   Fri Nov 14 21:00:00 2025 +0000
      GIT

    output, status = run_zone_with_input(input, "--zone", "EST")

    status.should eq(0)
    lines = output.lines

    # All three timestamps should be converted
    lines[0].should match(/6:00 PM EST/)  # 23:00 UTC = 18:00 EST
    lines[3].should match(/5:00 PM EST/)  # 22:00 UTC = 17:00 EST
    lines[6].should match(/4:00 PM EST/)  # 21:00 UTC = 16:00 EST
  end

  it "does not corrupt commit hashes" do
    # Commit hash 18cb3e41e88aa1ebe1785815368ac12500a818e8 contains "1785815368"
    # which is a valid unix timestamp (Aug 03, 2026). The hash should NOT be converted
    # because it's part of a hexadecimal string.
    input = <<-GIT
      commit 18cb3e41e88aa1ebe1785815368ac12500a818e8
      Author: Test User <test@example.com>
      Date:   Fri Nov 14 10:00:00 2025 +0000

          Fix handling of timestamps in git logs
      GIT

    output, status = run_zone_with_input(input, "--zone", "EST")

    status.should eq(0)
    # Commit hash should remain intact (not corrupted by timestamp conversion)
    output.should match(/commit 18cb3e41e88aa1ebe1785815368ac12500a818e8/)
    # Date line should still be converted
    output.should match(/Nov 14, 2025/)
    output.should match(/5:00 AM EST/)
  end
end
