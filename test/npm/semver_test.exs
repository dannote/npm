defmodule NPM.SemverTest do
  use ExUnit.Case, async: true

  describe "npm semver: complete caret behavior suite" do
    test "^1.2.3 allows >=1.2.3 <2.0.0" do
      assert NPMSemver.matches?("1.2.3", "^1.2.3")
      assert NPMSemver.matches?("1.9.9", "^1.2.3")
      refute NPMSemver.matches?("2.0.0", "^1.2.3")
    end

    test "^0.2.3 allows >=0.2.3 <0.3.0" do
      assert NPMSemver.matches?("0.2.3", "^0.2.3")
      assert NPMSemver.matches?("0.2.9", "^0.2.3")
      refute NPMSemver.matches?("0.3.0", "^0.2.3")
    end

    test "^0.0.3 allows only 0.0.3" do
      assert NPMSemver.matches?("0.0.3", "^0.0.3")
      refute NPMSemver.matches?("0.0.4", "^0.0.3")
    end
  end

  describe "npm semver: complete tilde behavior suite" do
    test "~1.2.3 allows >=1.2.3 <1.3.0" do
      assert NPMSemver.matches?("1.2.3", "~1.2.3")
      assert NPMSemver.matches?("1.2.9", "~1.2.3")
      refute NPMSemver.matches?("1.3.0", "~1.2.3")
    end

    test "~0.2.3 allows >=0.2.3 <0.3.0" do
      assert NPMSemver.matches?("0.2.3", "~0.2.3")
      assert NPMSemver.matches?("0.2.9", "~0.2.3")
      refute NPMSemver.matches?("0.3.0", "~0.2.3")
    end

    test "~0 allows >=0.0.0 <1.0.0" do
      assert NPMSemver.matches?("0.0.0", "~0")
      assert NPMSemver.matches?("0.9.9", "~0")
      refute NPMSemver.matches?("1.0.0", "~0")
    end
  end

  describe "npm semver: hyphen range completeness" do
    test "1.0.0 - 3.0.0 includes boundaries" do
      assert NPMSemver.matches?("1.0.0", "1.0.0 - 3.0.0")
      assert NPMSemver.matches?("2.5.0", "1.0.0 - 3.0.0")
      assert NPMSemver.matches?("3.0.0", "1.0.0 - 3.0.0")
      refute NPMSemver.matches?("3.0.1", "1.0.0 - 3.0.0")
      refute NPMSemver.matches?("0.9.9", "1.0.0 - 3.0.0")
    end
  end

  describe "npm semver: complex union ranges" do
    test ">=1.0.0 <2.0.0 || >=3.0.0 <4.0.0" do
      assert NPMSemver.matches?("1.5.0", ">=1.0.0 <2.0.0 || >=3.0.0 <4.0.0")
      refute NPMSemver.matches?("2.5.0", ">=1.0.0 <2.0.0 || >=3.0.0 <4.0.0")
      assert NPMSemver.matches?("3.5.0", ">=1.0.0 <2.0.0 || >=3.0.0 <4.0.0")
      refute NPMSemver.matches?("4.0.0", ">=1.0.0 <2.0.0 || >=3.0.0 <4.0.0")
    end
  end

  describe "npm semver: comparator negation" do
    test "!= is not valid npm semver but != works as separate constraints" do
      # npm uses >= and < to exclude specific versions
      assert NPMSemver.matches?("1.0.1", ">1.0.0 <1.0.2")
      refute NPMSemver.matches?("1.0.0", ">1.0.0 <1.0.2")
      refute NPMSemver.matches?("1.0.2", ">1.0.0 <1.0.2")
    end
  end

  describe "npm semver: multiple caret matches" do
    test "^1 same as ^1.0.0" do
      assert NPMSemver.matches?("1.0.0", "^1")
      assert NPMSemver.matches?("1.9.9", "^1")
      refute NPMSemver.matches?("2.0.0", "^1")
    end

    test "^0 same as ^0.0.0" do
      assert NPMSemver.matches?("0.0.0", "^0")
    end
  end

  describe "npm semver: x-range completeness" do
    test "* matches everything" do
      assert NPMSemver.matches?("0.0.0", "*")
      assert NPMSemver.matches?("99.99.99", "*")
    end

    test "1.* matches any 1.x.y" do
      assert NPMSemver.matches?("1.0.0", "1.*")
      assert NPMSemver.matches?("1.99.99", "1.*")
      refute NPMSemver.matches?("2.0.0", "1.*")
    end
  end

  describe "npm semver: pre-release detection" do
    test "pre-release version is detected by VersionUtil" do
      assert NPM.VersionUtil.prerelease?("1.0.0-alpha")
      assert NPM.VersionUtil.prerelease?("1.0.0-beta.1")
      assert NPM.VersionUtil.prerelease?("2.0.0-rc.1")
      refute NPM.VersionUtil.prerelease?("1.0.0")
    end
  end

  describe "npm semver: comparator edge cases" do
    test "<=2.0.0 includes 2.0.0" do
      assert NPMSemver.matches?("2.0.0", "<=2.0.0")
    end

    test ">1.0.0 excludes 1.0.0" do
      refute NPMSemver.matches?("1.0.0", ">1.0.0")
      assert NPMSemver.matches?("1.0.1", ">1.0.0")
    end

    test "<2.0.0 excludes 2.0.0" do
      refute NPMSemver.matches?("2.0.0", "<2.0.0")
      assert NPMSemver.matches?("1.9.9", "<2.0.0")
    end

    test ">=1.0.0 includes 1.0.0" do
      assert NPMSemver.matches?("1.0.0", ">=1.0.0")
    end
  end

  describe "npm semver: complex ranges" do
    test ">=1.0.0 <=2.0.0" do
      assert NPMSemver.matches?("1.0.0", ">=1.0.0 <=2.0.0")
      assert NPMSemver.matches?("2.0.0", ">=1.0.0 <=2.0.0")
      refute NPMSemver.matches?("2.0.1", ">=1.0.0 <=2.0.0")
    end

    test "triple || union" do
      assert NPMSemver.matches?("1.0.0", "^1.0.0 || ^2.0.0 || ^3.0.0")
      assert NPMSemver.matches?("2.5.0", "^1.0.0 || ^2.0.0 || ^3.0.0")
      assert NPMSemver.matches?("3.1.0", "^1.0.0 || ^2.0.0 || ^3.0.0")
      refute NPMSemver.matches?("4.0.0", "^1.0.0 || ^2.0.0 || ^3.0.0")
    end

    test ">1.0.0 <1.2.0" do
      assert NPMSemver.matches?("1.0.1", ">1.0.0 <1.2.0")
      assert NPMSemver.matches?("1.1.0", ">1.0.0 <1.2.0")
      refute NPMSemver.matches?("1.2.0", ">1.0.0 <1.2.0")
    end
  end

  describe "npm semver: caret zero-version semantics" do
    test "^0.0.0 matches only 0.0.0" do
      assert NPMSemver.matches?("0.0.0", "^0.0.0")
      refute NPMSemver.matches?("0.0.1", "^0.0.0")
    end

    test "^0.1.0 allows patch bumps" do
      assert NPMSemver.matches?("0.1.0", "^0.1.0")
      assert NPMSemver.matches?("0.1.5", "^0.1.0")
      refute NPMSemver.matches?("0.2.0", "^0.1.0")
    end

    test "^0.0.1 pins exact" do
      assert NPMSemver.matches?("0.0.1", "^0.0.1")
      refute NPMSemver.matches?("0.0.2", "^0.0.1")
    end
  end

  describe "npm semver: tilde edge cases" do
    test "~0.0.1 allows patch bumps" do
      assert NPMSemver.matches?("0.0.1", "~0.0.1")
      assert NPMSemver.matches?("0.0.5", "~0.0.1")
      refute NPMSemver.matches?("0.1.0", "~0.0.1")
    end

    test "~1 matches any 1.x" do
      assert NPMSemver.matches?("1.0.0", "~1")
      assert NPMSemver.matches?("1.5.0", "~1")
      refute NPMSemver.matches?("2.0.0", "~1")
    end
  end

  describe "npm semver: ported from node-semver test fixtures" do
    test "^1.0.0 matches 1.0.1" do
      assert NPMSemver.matches?("1.0.1", "^1.0.0")
    end

    test "^1.0.0 does not match 2.0.0" do
      refute NPMSemver.matches?("2.0.0", "^1.0.0")
    end

    test "^0.0.1 matches only 0.0.1" do
      assert NPMSemver.matches?("0.0.1", "^0.0.1")
      refute NPMSemver.matches?("0.0.2", "^0.0.1")
    end

    test "~1.2.3 matches 1.2.5 but not 1.3.0" do
      assert NPMSemver.matches?("1.2.5", "~1.2.3")
      refute NPMSemver.matches?("1.3.0", "~1.2.3")
    end

    test ">=1.0.0 <2.0.0 is correct range" do
      assert NPMSemver.matches?("1.0.0", ">=1.0.0 <2.0.0")
      assert NPMSemver.matches?("1.9.9", ">=1.0.0 <2.0.0")
      refute NPMSemver.matches?("0.9.9", ">=1.0.0 <2.0.0")
      refute NPMSemver.matches?("2.0.0", ">=1.0.0 <2.0.0")
    end

    test "1.0.0 - 2.0.0 hyphen range" do
      assert NPMSemver.matches?("1.0.0", "1.0.0 - 2.0.0")
      assert NPMSemver.matches?("2.0.0", "1.0.0 - 2.0.0")
      refute NPMSemver.matches?("2.0.1", "1.0.0 - 2.0.0")
    end

    test "^0.1.0 matches 0.1.x only" do
      assert NPMSemver.matches?("0.1.0", "^0.1.0")
      assert NPMSemver.matches?("0.1.9", "^0.1.0")
      refute NPMSemver.matches?("0.2.0", "^0.1.0")
    end

    test "x ranges" do
      assert NPMSemver.matches?("1.5.0", "1.x")
      assert NPMSemver.matches?("1.0.0", "1.x.x")
      assert NPMSemver.matches?("1.2.5", "1.2.x")
      refute NPMSemver.matches?("2.0.0", "1.x")
    end

    test "|| union" do
      assert NPMSemver.matches?("1.0.0", "^1.0.0 || ^2.0.0")
      assert NPMSemver.matches?("2.5.0", "^1.0.0 || ^2.0.0")
      refute NPMSemver.matches?("3.0.0", "^1.0.0 || ^2.0.0")
    end

    test "exact version" do
      assert NPMSemver.matches?("1.0.0", "1.0.0")
      refute NPMSemver.matches?("1.0.1", "1.0.0")
    end

    test ">=0.0.0 matches everything" do
      assert NPMSemver.matches?("0.0.0", ">=0.0.0")
      assert NPMSemver.matches?("999.999.999", ">=0.0.0")
    end
  end

  describe "npm semver: exact version equality" do
    test "exact match" do
      assert NPMSemver.matches?("1.2.3", "1.2.3")
    end

    test "exact no match" do
      refute NPMSemver.matches?("1.2.4", "1.2.3")
    end
  end
end
