defmodule NPM.SemverUtilTest do
  use ExUnit.Case, async: true

  describe "SemverUtil: max_satisfying" do
    test "finds highest matching version" do
      versions = ["1.0.0", "1.1.0", "1.2.0", "2.0.0"]
      assert {:ok, "1.2.0"} = NPM.SemverUtil.max_satisfying(versions, "^1.0.0")
    end

    test "returns :none when nothing matches" do
      versions = ["1.0.0", "1.1.0"]
      assert :none = NPM.SemverUtil.max_satisfying(versions, "^2.0.0")
    end
  end

  describe "SemverUtil: min_satisfying" do
    test "finds lowest matching version" do
      versions = ["1.0.0", "1.1.0", "1.2.0"]
      assert {:ok, "1.0.0"} = NPM.SemverUtil.min_satisfying(versions, "^1.0.0")
    end
  end

  describe "SemverUtil: filter" do
    test "returns only matching versions" do
      versions = ["0.9.0", "1.0.0", "1.1.0", "2.0.0"]
      result = NPM.SemverUtil.filter(versions, "^1.0.0")
      assert "1.0.0" in result
      assert "1.1.0" in result
      refute "0.9.0" in result
      refute "2.0.0" in result
    end
  end

  describe "SemverUtil: any_satisfying?" do
    test "returns true when match exists" do
      assert NPM.SemverUtil.any_satisfying?(["1.0.0", "2.0.0"], "^1.0.0")
    end

    test "returns false when no match" do
      refute NPM.SemverUtil.any_satisfying?(["1.0.0"], "^2.0.0")
    end
  end

  describe "SemverUtil: empty list edge cases" do
    test "max_satisfying with empty list" do
      assert :none = NPM.SemverUtil.max_satisfying([], "^1.0.0")
    end

    test "min_satisfying with empty list" do
      assert :none = NPM.SemverUtil.min_satisfying([], "^1.0.0")
    end

    test "filter with empty list returns empty" do
      assert [] = NPM.SemverUtil.filter([], "^1.0.0")
    end

    test "any_satisfying? with empty list returns false" do
      refute NPM.SemverUtil.any_satisfying?([], "^1.0.0")
    end
  end

  describe "SemverUtil: update_type" do
    test "detects major update" do
      assert :major = NPM.SemverUtil.update_type("1.0.0", "2.0.0")
    end

    test "detects minor update" do
      assert :minor = NPM.SemverUtil.update_type("1.0.0", "1.1.0")
    end

    test "detects patch update" do
      assert :patch = NPM.SemverUtil.update_type("1.0.0", "1.0.1")
    end

    test "detects no change" do
      assert :none = NPM.SemverUtil.update_type("1.0.0", "1.0.0")
    end

    test "handles invalid version gracefully" do
      assert :none = NPM.SemverUtil.update_type("not-a-version", "1.0.0")
    end
  end

  describe "SemverUtil: max_satisfying with tilde ranges" do
    test "tilde constrains to patch versions" do
      versions = ["1.2.0", "1.2.5", "1.3.0", "2.0.0"]
      {:ok, best} = NPM.SemverUtil.max_satisfying(versions, "~1.2.0")
      assert best == "1.2.5"
    end
  end

  describe "SemverUtil: max_satisfying with exact version" do
    test "exact version matches only that version" do
      versions = ["1.0.0", "1.0.1", "2.0.0"]
      {:ok, best} = NPM.SemverUtil.max_satisfying(versions, "1.0.0")
      assert best == "1.0.0"
    end
  end

  describe "SemverUtil: filter with OR ranges" do
    test "filter with union range" do
      versions = ["1.0.0", "2.0.0", "3.0.0", "4.0.0"]
      result = NPM.SemverUtil.filter(versions, "^1.0.0 || ^3.0.0")
      assert "1.0.0" in result
      assert "3.0.0" in result
      refute "2.0.0" in result
      refute "4.0.0" in result
    end
  end

  describe "SemverUtil: max_satisfying with >= range" do
    test "finds max for >= range" do
      versions = ["1.0.0", "2.0.0", "3.0.0"]
      {:ok, best} = NPM.SemverUtil.max_satisfying(versions, ">=2.0.0")
      assert best == "3.0.0"
    end
  end

  describe "SemverUtil: max_satisfying precision" do
    test "returns exact highest satisfying" do
      versions = ["1.0.0", "1.0.1", "1.0.2", "1.1.0", "2.0.0"]
      {:ok, v} = NPM.SemverUtil.max_satisfying(versions, "~1.0.0")
      assert v == "1.0.2"
    end
  end

  describe "SemverUtil: max_satisfying with exact match only" do
    test "exact version only matches itself" do
      versions = ["1.0.0", "1.0.1", "2.0.0"]
      {:ok, v} = NPM.SemverUtil.max_satisfying(versions, "1.0.0")
      assert v == "1.0.0"
    end
  end

  describe "SemverUtil: update_type across major boundary" do
    test "0.x to 1.x is major" do
      assert :major = NPM.SemverUtil.update_type("0.9.0", "1.0.0")
    end

    test "1.x to 1.x.y is patch" do
      assert :patch = NPM.SemverUtil.update_type("1.0.0", "1.0.1")
    end
  end

  describe "SemverUtil: filter with tilde" do
    test "tilde constrains to minor version" do
      versions = ["1.2.0", "1.2.5", "1.3.0", "2.0.0"]
      result = NPM.SemverUtil.filter(versions, "~1.2.0")
      assert "1.2.0" in result
      assert "1.2.5" in result
      refute "1.3.0" in result
    end
  end

  describe "SemverUtil: min_satisfying with >= range" do
    test "finds minimum satisfying version" do
      versions = ["1.0.0", "1.5.0", "2.0.0", "3.0.0"]
      {:ok, v} = NPM.SemverUtil.min_satisfying(versions, ">=1.5.0")
      assert v == "1.5.0"
    end

    test "returns error when no version satisfies" do
      versions = ["1.0.0", "2.0.0"]
      result = NPM.SemverUtil.min_satisfying(versions, ">=5.0.0")
      assert result == :none
    end
  end

  describe "SemverUtil: update_type minor and same" do
    test "minor bump detected" do
      assert :minor = NPM.SemverUtil.update_type("1.0.0", "1.1.0")
    end

    test "same version returns nil" do
      assert :none == NPM.SemverUtil.update_type("1.0.0", "1.0.0")
    end
  end
end
