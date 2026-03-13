defmodule NPM.SemverRangeTest do
  @moduledoc """
  Additional range tests ported from npm/node-semver gtr/ltr fixtures.
  These versions should NOT satisfy their ranges — they are either above or below.
  Source: https://github.com/npm/node-semver/tree/main/test/fixtures
  """
  use ExUnit.Case, async: true

  # From version-gt-range.js — version is ABOVE the range (doesn't satisfy)
  # Entries with `true` (loose mode) are excluded
  @above_range [
    {"~1.2.2", "1.3.0"},
    {"1.0.0 - 2.0.0", "2.0.1"},
    {"1.0.0", "2.0.0"},
    {"<=2.0.0", "2.1.1"},
    {"<=2.0.0", "3.2.9"},
    {"<2.0.0", "2.0.0"},
    {"0.1.20 || 1.2.4", "1.2.5"},
    {"2.x.x", "3.0.0"},
    {"1.2.x", "1.3.0"},
    {"1.2.x || 2.x", "3.0.0"},
    {"2.*.*", "5.0.1"},
    {"1.2.*", "1.3.3"},
    {"1.2.* || 2.*", "4.0.0"},
    {"2", "3.0.0"},
    {"2.3", "2.4.2"},
    {"~2.4", "2.5.0"},
    {"~2.4", "2.5.5"},
    {"~>3.2.1", "3.3.0"},
    {"~1", "2.2.3"},
    {"~>1", "2.2.4"},
    {"~> 1", "3.2.3"},
    {"~1.0", "1.1.2"},
    {"~ 1.0", "1.1.0"},
    {"<1.2", "1.2.0"},
    {"< 1.2", "1.2.1"},
    {"~v0.5.4-pre", "0.6.0"},
    {"=0.7.x", "0.8.0"},
    {"<0.7.x", "0.7.0"},
    {"1.0.0 - 2.0.0", "2.2.3"},
    {"1.0.0", "1.0.1"},
    {"<=2.0.0", "3.0.0"},
    {"<=2.0.0", "2.9999.9999"},
    {"<=2.0.0", "2.2.9"},
    {"<2.0.0", "2.9999.9999"},
    {"<2.0.0", "2.2.9"},
    {"2.x.x", "3.1.3"},
    {"1.2.x", "1.3.3"},
    {"1.2.x || 2.x", "3.1.3"},
    {"2.*.*", "3.1.3"},
    {"1.2.* || 2.*", "3.1.3"},
    {"2", "3.1.2"},
    {"2.3", "2.4.1"},
    {"~>3.2.1", "3.3.2"},
    {"~>1", "2.2.3"},
    {"~1.0", "1.1.0"},
    {"<1", "1.0.0"},
    {"=0.7.x", "0.8.2"},
    {"<0.7.x", "0.7.2"}
  ]

  # From version-lt-range.js — version is BELOW the range (doesn't satisfy)
  @below_range [
    {"~1.2.2", "1.2.1"},
    {"1.0.0 - 2.0.0", "0.0.1"},
    {"1.0.0", "0.0.0"},
    {">=2.0.0", "1.1.1"},
    {">=2.0.0", "1.2.9"},
    {">2.0.0", "2.0.0"},
    {"0.1.20 || 1.2.4", "0.1.5"},
    {"2.x.x", "1.0.0"},
    {"1.2.x", "1.1.0"},
    {"1.2.x || 2.x", "1.0.0"},
    {"2.*.*", "1.0.1"},
    {"1.2.*", "1.1.3"},
    {"1.2.* || 2.*", "1.1.9999"},
    {"2", "1.0.0"},
    {"2.3", "2.2.2"},
    {"~2.4", "2.3.0"},
    {"~2.4", "2.3.5"},
    {"~>3.2.1", "3.2.0"},
    {"~1", "0.2.3"},
    {"~>1", "0.2.4"},
    {"~> 1", "0.2.3"},
    {"~1.0", "0.1.2"},
    {"~ 1.0", "0.1.0"},
    {">1.2", "1.2.0"},
    {"> 1.2", "1.2.1"},
    {"=0.7.x", "0.6.0"},
    {">=0.7.x", "0.6.0"},
    {"1.0.0 - 2.0.0", "0.2.3"},
    {"1.0.0", "0.0.1"},
    {">=2.0.0", "1.0.0"},
    {">=2.0.0", "1.9999.9999"},
    {">2.0.0", "1.2.9"},
    {"2.x.x", "1.1.3"},
    {"1.2.x", "1.1.3"},
    {"1.2.x || 2.x", "1.1.3"},
    {"2.*.*", "1.1.3"},
    {"1.2.* || 2.*", "1.1.3"},
    {"2", "1.9999.9999"},
    {"2.3", "2.2.1"},
    {"~>3.2.1", "2.3.2"},
    {"~>1", "0.2.3"},
    {"~1.0", "0.0.0"},
    {">1", "1.0.0"},
    {"=0.7.x", "0.6.2"},
    {">=0.7.x", "0.6.2"}
  ]

  describe "npm/node-semver version-gt-range: above range (ported)" do
    for {range, version} <- @above_range do
      @range range
      @version version
      test "#{version} is above #{range}" do
        refute NPMSemver.matches?(@version, @range),
               "Expected #{@version} to NOT satisfy #{@range} (version is above range)"
      end
    end
  end

  describe "npm/node-semver version-lt-range: below range (ported)" do
    for {range, version} <- @below_range do
      @range range
      @version version
      test "#{version} is below #{range}" do
        refute NPMSemver.matches?(@version, @range),
               "Expected #{@version} to NOT satisfy #{@range} (version is below range)"
      end
    end
  end
end
