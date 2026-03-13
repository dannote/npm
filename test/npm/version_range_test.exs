defmodule NPM.VersionRangeTest do
  use ExUnit.Case, async: true

  describe "compatible?" do
    test "overlapping caret ranges" do
      assert NPM.VersionRange.compatible?("^1.0.0", "^1.5.0")
    end

    test "non-overlapping major ranges" do
      refute NPM.VersionRange.compatible?("^1.0.0", "^2.0.0")
    end

    test "exact version in range" do
      assert NPM.VersionRange.compatible?("1.5.0", "^1.0.0")
    end

    test "any range compatible with everything" do
      assert NPM.VersionRange.compatible?("*", "^5.0.0")
    end
  end

  describe "max_satisfying" do
    test "finds highest matching version" do
      versions = ["1.0.0", "1.5.0", "2.0.0", "1.9.0"]
      assert "1.9.0" = NPM.VersionRange.max_satisfying(versions, "^1.0.0")
    end

    test "returns nil when none match" do
      assert nil == NPM.VersionRange.max_satisfying(["1.0.0"], "^2.0.0")
    end

    test "exact match" do
      assert "1.5.0" = NPM.VersionRange.max_satisfying(["1.0.0", "1.5.0", "2.0.0"], "1.5.0")
    end
  end

  describe "min_satisfying" do
    test "finds lowest matching version" do
      versions = ["1.0.0", "1.5.0", "2.0.0", "1.9.0"]
      assert "1.0.0" = NPM.VersionRange.min_satisfying(versions, "^1.0.0")
    end

    test "returns nil when none match" do
      assert nil == NPM.VersionRange.min_satisfying(["3.0.0"], "^2.0.0")
    end
  end

  describe "exact?" do
    test "true for pinned version" do
      assert NPM.VersionRange.exact?("1.2.3")
    end

    test "false for caret range" do
      refute NPM.VersionRange.exact?("^1.2.3")
    end

    test "false for tilde range" do
      refute NPM.VersionRange.exact?("~1.2.3")
    end

    test "false for star" do
      refute NPM.VersionRange.exact?("*")
    end
  end

  describe "major" do
    test "extracts major from version" do
      assert 1 = NPM.VersionRange.major("1.2.3")
    end

    test "extracts major from caret range" do
      assert 2 = NPM.VersionRange.major("^2.0.0")
    end

    test "nil for star" do
      assert nil == NPM.VersionRange.major("*")
    end
  end

  describe "classify" do
    test "classifies caret range" do
      assert :caret = NPM.VersionRange.classify("^1.0.0")
    end

    test "classifies tilde range" do
      assert :tilde = NPM.VersionRange.classify("~1.0.0")
    end

    test "classifies exact version" do
      assert :exact = NPM.VersionRange.classify("1.2.3")
    end

    test "classifies star as any" do
      assert :any = NPM.VersionRange.classify("*")
    end

    test "classifies hyphen range" do
      assert :hyphen = NPM.VersionRange.classify("1.0.0 - 2.0.0")
    end

    test "classifies or range" do
      assert :or_range = NPM.VersionRange.classify("^1.0.0 || ^2.0.0")
    end

    test "classifies comparator" do
      assert :comparator = NPM.VersionRange.classify(">=1.0.0")
    end
  end

  describe "describe" do
    test "describes caret range" do
      assert "compatible with 1.0.0" = NPM.VersionRange.describe("^1.0.0")
    end

    test "describes exact version" do
      assert "exactly 1.2.3" = NPM.VersionRange.describe("1.2.3")
    end

    test "describes any" do
      assert "any version" = NPM.VersionRange.describe("*")
    end

    test "describes tilde" do
      assert "approximately 1.2.0" = NPM.VersionRange.describe("~1.2.0")
    end
  end
end
