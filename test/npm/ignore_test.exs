defmodule NPM.IgnoreTest do
  use ExUnit.Case, async: true

  describe "parse" do
    test "parses patterns" do
      content = "node_modules\n*.log\ndist/\n"
      patterns = NPM.Ignore.parse(content)
      assert "node_modules" in patterns
      assert "*.log" in patterns
      assert "dist/" in patterns
    end

    test "ignores comments" do
      patterns = NPM.Ignore.parse("# comment\nnode_modules\n# another\n")
      assert patterns == ["node_modules"]
    end

    test "ignores blank lines" do
      patterns = NPM.Ignore.parse("\n\nnode_modules\n\n")
      assert patterns == ["node_modules"]
    end

    test "empty content" do
      assert [] = NPM.Ignore.parse("")
    end

    test "deduplicates" do
      patterns = NPM.Ignore.parse("dist\ndist\n")
      assert patterns == ["dist"]
    end
  end

  describe "ignored?" do
    test "always ignores .git" do
      assert NPM.Ignore.ignored?(".git", [])
    end

    test "always ignores node_modules" do
      assert NPM.Ignore.ignored?("node_modules", [])
    end

    test "always ignores .DS_Store" do
      assert NPM.Ignore.ignored?(".DS_Store", [])
    end

    test "never ignores package.json" do
      refute NPM.Ignore.ignored?("package.json", ["package.json"])
    end

    test "never ignores README.md" do
      refute NPM.Ignore.ignored?("README.md", ["README.md"])
    end

    test "never ignores LICENSE (case insensitive)" do
      refute NPM.Ignore.ignored?("license", ["license"])
    end

    test "matches file pattern" do
      assert NPM.Ignore.ignored?("src/test.js", ["src/test.js"])
    end

    test "matches directory pattern" do
      assert NPM.Ignore.ignored?("dist/index.js", ["dist/"])
    end

    test "matches basename pattern" do
      assert NPM.Ignore.ignored?("src/debug.log", ["debug.log"])
    end

    test "not ignored when no pattern matches" do
      refute NPM.Ignore.ignored?("lib/index.js", ["dist/", "test/"])
    end
  end

  describe "always_ignored" do
    test "contains .git and node_modules" do
      always = NPM.Ignore.always_ignored()
      assert ".git" in always
      assert "node_modules" in always
    end
  end

  describe "never_ignored" do
    test "contains package.json and README" do
      never = NPM.Ignore.never_ignored()
      assert "package.json" in never
      assert "README.md" in never
    end
  end

  describe "effective_patterns" do
    @tag :tmp_dir
    test "prefers .npmignore over .gitignore", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".npmignore"), "test/\n")
      File.write!(Path.join(dir, ".gitignore"), "node_modules\n")

      patterns = NPM.Ignore.effective_patterns(dir)
      assert "test/" in patterns
      refute "node_modules" in patterns
    end

    @tag :tmp_dir
    test "falls back to .gitignore", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".gitignore"), "dist/\n")

      patterns = NPM.Ignore.effective_patterns(dir)
      assert "dist/" in patterns
    end

    @tag :tmp_dir
    test "empty when no ignore files", %{tmp_dir: dir} do
      assert [] = NPM.Ignore.effective_patterns(dir)
    end
  end

  describe "read" do
    @tag :tmp_dir
    test "reads ignore file", %{tmp_dir: dir} do
      path = Path.join(dir, ".npmignore")
      File.write!(path, "test/\n*.log\n")

      patterns = NPM.Ignore.read(path)
      assert "test/" in patterns
      assert "*.log" in patterns
    end

    test "empty for missing file" do
      assert [] = NPM.Ignore.read("/tmp/nonexistent_#{System.unique_integer([:positive])}")
    end
  end
end
