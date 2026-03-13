defmodule NPM.NodeVersionTest do
  use ExUnit.Case, async: true

  describe "detect" do
    @tag :tmp_dir
    test "reads .nvmrc", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".nvmrc"), "v20.10.0\n")
      assert {:ok, "20.10.0", ".nvmrc"} = NPM.NodeVersion.detect(dir)
    end

    @tag :tmp_dir
    test "reads .node-version", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".node-version"), "18.19.0\n")
      assert {:ok, "18.19.0", ".node-version"} = NPM.NodeVersion.detect(dir)
    end

    @tag :tmp_dir
    test "reads .tool-versions", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".tool-versions"), "nodejs 20.10.0\nruby 3.2.0\n")
      assert {:ok, "20.10.0", ".tool-versions"} = NPM.NodeVersion.detect(dir)
    end

    @tag :tmp_dir
    test "prefers .nvmrc over .node-version", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".nvmrc"), "20.10.0\n")
      File.write!(Path.join(dir, ".node-version"), "18.0.0\n")
      assert {:ok, "20.10.0", ".nvmrc"} = NPM.NodeVersion.detect(dir)
    end

    @tag :tmp_dir
    test "not found when no version files", %{tmp_dir: dir} do
      assert :not_found = NPM.NodeVersion.detect(dir)
    end
  end

  describe "parse_nvmrc" do
    test "strips v prefix" do
      assert "20.10.0" = NPM.NodeVersion.parse_nvmrc("v20.10.0")
    end

    test "trims whitespace" do
      assert "18.0.0" = NPM.NodeVersion.parse_nvmrc("  18.0.0  \n")
    end

    test "major only" do
      assert "20" = NPM.NodeVersion.parse_nvmrc("20")
    end
  end

  describe "parse_tool_versions" do
    test "extracts nodejs version" do
      content = "nodejs 20.10.0\npython 3.11.0\n"
      assert "20.10.0" = NPM.NodeVersion.parse_tool_versions(content)
    end

    test "handles v prefix" do
      assert "18.0.0" = NPM.NodeVersion.parse_tool_versions("nodejs v18.0.0\n")
    end

    test "nil when no nodejs entry" do
      assert nil == NPM.NodeVersion.parse_tool_versions("ruby 3.2.0\n")
    end
  end

  describe "major_only?" do
    test "true for major only" do
      assert NPM.NodeVersion.major_only?("20")
    end

    test "false for full version" do
      refute NPM.NodeVersion.major_only?("20.10.0")
    end
  end

  describe "alias?" do
    test "true for lts/*" do
      assert NPM.NodeVersion.alias?("lts/*")
    end

    test "true for lts/hydrogen" do
      assert NPM.NodeVersion.alias?("lts/hydrogen")
    end

    test "true for stable" do
      assert NPM.NodeVersion.alias?("stable")
    end

    test "false for version" do
      refute NPM.NodeVersion.alias?("20.10.0")
    end
  end

  describe "normalize" do
    test "adds .0.0 to major" do
      assert "20.0.0" = NPM.NodeVersion.normalize("20")
    end

    test "adds .0 to major.minor" do
      assert "20.10.0" = NPM.NodeVersion.normalize("20.10")
    end

    test "keeps full version" do
      assert "20.10.0" = NPM.NodeVersion.normalize("20.10.0")
    end

    test "strips v prefix" do
      assert "18.0.0" = NPM.NodeVersion.normalize("v18")
    end
  end
end
