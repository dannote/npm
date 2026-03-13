defmodule NPM.FormatTest do
  use ExUnit.Case, async: true

  describe "Format.bytes" do
    test "formats bytes" do
      assert "500 B" = NPM.Format.bytes(500)
    end

    test "formats kilobytes" do
      assert "1.5 KB" = NPM.Format.bytes(1536)
    end

    test "formats megabytes" do
      assert "10.0 MB" = NPM.Format.bytes(10_485_760)
    end

    test "formats gigabytes" do
      assert "1.0 GB" = NPM.Format.bytes(1_073_741_824)
    end
  end

  describe "Format.duration" do
    test "formats microseconds" do
      assert "500µs" = NPM.Format.duration(500)
    end

    test "formats milliseconds" do
      assert "150ms" = NPM.Format.duration(150_000)
    end

    test "formats seconds" do
      assert "2.5s" = NPM.Format.duration(2_500_000)
    end
  end

  describe "Format.package" do
    test "formats name@version" do
      assert "lodash@4.17.21" = NPM.Format.package("lodash", "4.17.21")
    end
  end

  describe "Format.pluralize" do
    test "singular" do
      assert "1 package" = NPM.Format.pluralize(1, "package", "packages")
    end

    test "plural" do
      assert "5 packages" = NPM.Format.pluralize(5, "package", "packages")
    end

    test "zero" do
      assert "0 packages" = NPM.Format.pluralize(0, "package", "packages")
    end
  end

  describe "Format.truncate" do
    test "short string unchanged" do
      assert "hi" = NPM.Format.truncate("hi", 10)
    end

    test "long string truncated" do
      result = NPM.Format.truncate("this is a very long string", 10)
      assert String.ends_with?(result, "...")
      assert byte_size(result) <= 10
    end
  end

  describe "Format: pluralize edge cases" do
    test "pluralize with 0" do
      assert "0 items" = NPM.Format.pluralize(0, "item", "items")
    end

    test "pluralize with 1" do
      assert "1 item" = NPM.Format.pluralize(1, "item", "items")
    end

    test "pluralize with 100" do
      assert "100 items" = NPM.Format.pluralize(100, "item", "items")
    end
  end

  describe "Format: bytes precision" do
    test "small bytes show exact count" do
      assert "500 B" = NPM.Format.bytes(500)
    end
  end

  describe "Format: package display with special chars" do
    test "handles version with pre-release tag" do
      assert "pkg@1.0.0-beta.1" = NPM.Format.package("pkg", "1.0.0-beta.1")
    end
  end

  describe "Format: truncate edge cases" do
    test "truncate with exact length" do
      result = NPM.Format.truncate("hello", 5)
      assert result == "hello"
    end

    test "truncate with length shorter than string" do
      result = NPM.Format.truncate("hello world", 5)
      assert String.length(result) <= 8
      assert result =~ "..."
    end
  end

  describe "Format: bytes edge cases" do
    test "formats gigabytes" do
      result = NPM.Format.bytes(2_000_000_000)
      assert result =~ "GB"
    end

    test "formats exact kilobyte" do
      result = NPM.Format.bytes(1024)
      assert result =~ "1"
    end
  end

  describe "Format: package display" do
    test "package formats name@version" do
      assert NPM.Format.package("lodash", "4.17.21") == "lodash@4.17.21"
    end

    test "package formats scoped name@version" do
      assert NPM.Format.package("@babel/core", "7.0.0") == "@babel/core@7.0.0"
    end
  end

  describe "Format: human-readable output helpers" do
    test "bytes formats file sizes" do
      assert NPM.Format.bytes(0) == "0 B"
      assert NPM.Format.bytes(1023) == "1023 B"
      assert NPM.Format.bytes(1024) =~ "KB"
      assert NPM.Format.bytes(1_048_576) =~ "MB"
    end

    test "duration formats microseconds" do
      assert NPM.Format.duration(0) =~ "0"
      assert NPM.Format.duration(1_500_000) =~ "1.5"
    end

    test "pluralize handles singular and plural" do
      assert NPM.Format.pluralize(1, "package", "packages") == "1 package"
      assert NPM.Format.pluralize(5, "package", "packages") == "5 packages"
      assert NPM.Format.pluralize(0, "package", "packages") == "0 packages"
    end

    test "truncate shortens long strings" do
      assert NPM.Format.truncate("hello", 10) == "hello"
      assert NPM.Format.truncate("hello world this is long", 10) =~ "..."
    end
  end

  describe "Format: duration formatting" do
    test "microseconds" do
      assert "500µs" = NPM.Format.duration(500)
    end

    test "milliseconds" do
      assert "5ms" = NPM.Format.duration(5_000)
      assert "100ms" = NPM.Format.duration(100_000)
    end

    test "seconds" do
      assert "1.5s" = NPM.Format.duration(1_500_000)
    end
  end

  describe "Format: bytes formatting complete range" do
    test "kilobytes" do
      assert String.ends_with?(NPM.Format.bytes(2048), "KB")
    end

    test "megabytes" do
      assert String.ends_with?(NPM.Format.bytes(5_242_880), "MB")
    end

    test "gigabytes" do
      assert String.ends_with?(NPM.Format.bytes(2_147_483_648), "GB")
    end
  end

  describe "Format: truncate behavior" do
    test "short string unchanged" do
      assert "hello" = NPM.Format.truncate("hello", 100)
    end

    test "long string gets ellipsis" do
      result = NPM.Format.truncate("a very long string that needs truncation", 15)
      assert byte_size(result) <= 15
      assert String.ends_with?(result, "...")
    end
  end
end
