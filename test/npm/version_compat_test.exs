defmodule NPM.VersionCompatTest do
  @moduledoc """
  Tests ported from npm/node-semver test fixtures for version parsing,
  comparison equality, and version incrementing.
  Source: https://github.com/npm/node-semver/tree/main/test/fixtures
  """
  use ExUnit.Case, async: true

  # Ported from node-semver/test/fixtures/valid-versions.js
  # [version_string, major, minor, patch]
  @valid_versions [
    {"1.0.0", 1, 0, 0},
    {"2.1.0", 2, 1, 0},
    {"3.2.1", 3, 2, 1},
    {"1.2.3-0", 1, 2, 3},
    {"1.2.3-123", 1, 2, 3},
    {"1.2.3-alpha", 1, 2, 3},
    {"1.2.3-alpha.1", 1, 2, 3},
    {"1.2.3+456", 1, 2, 3},
    {"1.2.3+build", 1, 2, 3},
    {"1.2.3-alpha+build", 1, 2, 3},
    {"0.0.0", 0, 0, 0},
    {"0.0.1", 0, 0, 1},
    {"0.1.0", 0, 1, 0},
    {"10.20.30", 10, 20, 30},
    {"100.200.300", 100, 200, 300}
  ]

  # Ported from node-semver/test/fixtures/equality.js
  # [version1, version2] — should be considered equal
  @equality [
    {"1.2.3", "1.2.3"},
    {"1.2.3-beta+build", "1.2.3-beta+otherbuild"},
    {"1.2.3+build", "1.2.3+otherbuild"}
  ]

  # Ported from node-semver/test/fixtures/increments.js
  # [version, increment_type, expected_result] — only major/minor/patch
  @increments [
    {"1.2.3", :major, "2.0.0"},
    {"1.2.3", :minor, "1.3.0"},
    {"1.2.3", :patch, "1.2.4"},
    {"0.0.0", :major, "1.0.0"},
    {"0.0.0", :minor, "0.1.0"},
    {"0.0.0", :patch, "0.0.1"},
    {"0.9.9", :major, "1.0.0"},
    {"1.9.9", :minor, "1.10.0"},
    {"1.0.9", :patch, "1.0.10"},
    {"10.20.30", :major, "11.0.0"},
    {"10.20.30", :minor, "10.21.0"},
    {"10.20.30", :patch, "10.20.31"}
  ]

  describe "npm/node-semver valid-versions: parse_triple (ported)" do
    for {version, major, minor, patch} <- @valid_versions do
      @version version
      @major major
      @minor minor
      @patch patch
      test "#{version} parses to {#{major}, #{minor}, #{patch}}" do
        # Strip pre-release and build metadata for triple parsing
        base = @version |> String.split("-") |> hd() |> String.split("+") |> hd()
        assert {:ok, {@major, @minor, @patch}} = NPM.VersionUtil.parse_triple(base)
      end
    end
  end

  describe "npm/node-semver valid-versions: major/minor extraction (ported)" do
    for {version, major, minor, _patch} <- @valid_versions do
      @version version
      @major major
      @minor minor
      test "major(#{version}) = #{major}" do
        assert @major == NPM.VersionUtil.major(@version)
      end

      test "minor(#{version}) = #{minor}" do
        assert @minor == NPM.VersionUtil.minor(@version)
      end
    end
  end

  describe "npm/node-semver equality (ported)" do
    for {v1, v2} <- @equality do
      @v1 v1
      @v2 v2
      test "#{v1} == #{v2}" do
        assert NPM.VersionUtil.compare(@v1, @v2) == :eq,
               "Expected #{@v1} == #{@v2}"
      end
    end
  end

  describe "npm/node-semver increments: bump_major (ported)" do
    for {version, :major, expected} <- @increments do
      @version version
      @expected expected
      test "bump_major(#{version}) = #{expected}" do
        assert @expected == NPM.VersionUtil.bump_major(@version)
      end
    end
  end

  describe "npm/node-semver increments: bump_minor (ported)" do
    for {version, :minor, expected} <- @increments do
      @version version
      @expected expected
      test "bump_minor(#{version}) = #{expected}" do
        assert @expected == NPM.VersionUtil.bump_minor(@version)
      end
    end
  end

  describe "npm/node-semver increments: bump_patch (ported)" do
    for {version, :patch, expected} <- @increments do
      @version version
      @expected expected
      test "bump_patch(#{version}) = #{expected}" do
        assert @expected == NPM.VersionUtil.bump_patch(@version)
      end
    end
  end
end
