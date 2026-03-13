defmodule NPM.ScriptsTest do
  use ExUnit.Case, async: true

  @scripts %{
    "start" => "node server.js",
    "test" => "jest",
    "build" => "tsc",
    "prebuild" => "rimraf dist",
    "postbuild" => "echo done",
    "lint" => "eslint .",
    "deploy" => "aws deploy",
    "pretest" => "lint"
  }

  describe "read" do
    @tag :tmp_dir
    test "reads scripts from package.json", %{tmp_dir: dir} do
      File.write!(
        Path.join(dir, "package.json"),
        ~s({"scripts":{"start":"node index.js","test":"jest"}})
      )

      {:ok, scripts} = NPM.Scripts.read(Path.join(dir, "package.json"))
      assert scripts["start"] == "node index.js"
      assert scripts["test"] == "jest"
    end

    @tag :tmp_dir
    test "returns empty map when no scripts", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"pkg"}))
      {:ok, scripts} = NPM.Scripts.read(Path.join(dir, "package.json"))
      assert scripts == %{}
    end

    test "returns error for missing file" do
      assert {:error, :enoent} =
               NPM.Scripts.read(
                 "/tmp/nonexistent_#{System.unique_integer([:positive])}/package.json"
               )
    end
  end

  describe "list" do
    test "returns sorted script names" do
      names = NPM.Scripts.list(@scripts)
      assert names == Enum.sort(names)
      assert "build" in names
      assert "deploy" in names
    end
  end

  describe "has?" do
    test "true for existing script" do
      assert NPM.Scripts.has?(@scripts, "build")
    end

    test "false for missing script" do
      refute NPM.Scripts.has?(@scripts, "nonexistent")
    end
  end

  describe "hooks_for" do
    test "finds pre and post hooks" do
      hooks = NPM.Scripts.hooks_for(@scripts, "build")
      assert hooks.pre == "rimraf dist"
      assert hooks.post == "echo done"
    end

    test "nil when no hooks exist" do
      hooks = NPM.Scripts.hooks_for(@scripts, "deploy")
      assert hooks.pre == nil
      assert hooks.post == nil
    end

    test "partial hooks (pre only)" do
      hooks = NPM.Scripts.hooks_for(@scripts, "test")
      assert hooks.pre == "lint"
      assert hooks.post == nil
    end
  end

  describe "categorize" do
    test "separates well-known from custom" do
      cat = NPM.Scripts.categorize(@scripts)
      assert "build" in cat.well_known
      assert "test" in cat.well_known
      assert "deploy" in cat.custom
      refute "deploy" in cat.well_known
    end

    test "pre/post hooks are well-known" do
      cat = NPM.Scripts.categorize(@scripts)
      assert "prebuild" in cat.well_known
      assert "postbuild" in cat.well_known
    end
  end

  describe "filter" do
    test "matches by pattern" do
      matched = NPM.Scripts.filter(@scripts, "build")
      assert Map.has_key?(matched, "build")
      assert Map.has_key?(matched, "prebuild")
      assert Map.has_key?(matched, "postbuild")
      refute Map.has_key?(matched, "test")
    end

    test "case insensitive" do
      matched = NPM.Scripts.filter(@scripts, "BUILD")
      assert Map.has_key?(matched, "build")
    end

    test "no matches returns empty" do
      assert %{} = NPM.Scripts.filter(@scripts, "zzz")
    end
  end

  describe "format" do
    test "formats scripts for display" do
      formatted = NPM.Scripts.format(%{"build" => "tsc", "test" => "jest"})
      assert formatted =~ "build: tsc"
      assert formatted =~ "test: jest"
    end

    test "empty scripts" do
      assert "No scripts defined." = NPM.Scripts.format(%{})
    end
  end

  describe "execution_order" do
    test "includes pre, main, and post" do
      order = NPM.Scripts.execution_order(@scripts, "build")
      assert order == ["prebuild", "build", "postbuild"]
    end

    test "skips missing hooks" do
      order = NPM.Scripts.execution_order(@scripts, "deploy")
      assert order == ["deploy"]
    end

    test "includes pre without post" do
      order = NPM.Scripts.execution_order(@scripts, "test")
      assert order == ["pretest", "test"]
    end

    test "missing script returns empty" do
      order = NPM.Scripts.execution_order(@scripts, "nonexistent")
      assert order == []
    end
  end
end
