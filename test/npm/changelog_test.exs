defmodule NPM.ChangelogTest do
  use ExUnit.Case, async: true

  @sample_changelog """
  # Changelog

  ## 2.0.0

  - Breaking: removed deprecated API
  - Added new feature

  ## 1.1.0

  - Added helper function
  - Fixed edge case

  ## 1.0.0

  - Initial release
  """

  describe "find" do
    @tag :tmp_dir
    test "finds CHANGELOG.md", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "CHANGELOG.md"), "# Changelog")
      assert {:ok, path} = NPM.Changelog.find(dir)
      assert String.ends_with?(path, "CHANGELOG.md")
    end

    @tag :tmp_dir
    test "finds HISTORY.md", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "HISTORY.md"), "# History")
      assert {:ok, _} = NPM.Changelog.find(dir)
    end

    @tag :tmp_dir
    test "returns none when no changelog", %{tmp_dir: dir} do
      assert :none = NPM.Changelog.find(dir)
    end
  end

  describe "read" do
    @tag :tmp_dir
    test "reads changelog content", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "CHANGELOG.md"), "# My Changelog")
      assert {:ok, "# My Changelog"} = NPM.Changelog.read(dir)
    end

    @tag :tmp_dir
    test "returns none when missing", %{tmp_dir: dir} do
      assert :none = NPM.Changelog.read(dir)
    end
  end

  describe "versions" do
    test "extracts version numbers" do
      versions = NPM.Changelog.versions(@sample_changelog)
      assert "2.0.0" in versions
      assert "1.1.0" in versions
      assert "1.0.0" in versions
    end

    test "empty for no versions" do
      assert [] = NPM.Changelog.versions("No version headers here")
    end

    test "handles bracketed versions" do
      content = "## [3.0.0]\n\n- stuff\n\n## [2.0.0]\n\n- things"
      versions = NPM.Changelog.versions(content)
      assert "3.0.0" in versions
      assert "2.0.0" in versions
    end
  end

  describe "version_entry" do
    test "extracts specific version section" do
      entry = NPM.Changelog.version_entry(@sample_changelog, "1.1.0")
      assert entry =~ "Added helper function"
      assert entry =~ "Fixed edge case"
      refute entry =~ "Initial release"
    end

    test "extracts last version" do
      entry = NPM.Changelog.version_entry(@sample_changelog, "1.0.0")
      assert entry =~ "Initial release"
    end

    test "nil for missing version" do
      assert nil == NPM.Changelog.version_entry(@sample_changelog, "9.9.9")
    end
  end

  describe "has_changelog?" do
    @tag :tmp_dir
    test "true when changelog exists", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "CHANGELOG.md"), "")
      assert NPM.Changelog.has_changelog?(dir)
    end

    @tag :tmp_dir
    test "false when no changelog", %{tmp_dir: dir} do
      refute NPM.Changelog.has_changelog?(dir)
    end
  end
end
