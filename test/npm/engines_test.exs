defmodule NPM.EnginesTest do
  use ExUnit.Case, async: true

  @pkg_with_engines %{"engines" => %{"node" => ">=18", "npm" => ">=9"}}
  @pkg_no_engines %{"name" => "simple"}

  describe "extract" do
    test "extracts engines map" do
      engines = NPM.Engines.extract(@pkg_with_engines)
      assert engines["node"] == ">=18"
      assert engines["npm"] == ">=9"
    end

    test "empty for no engines" do
      assert %{} = NPM.Engines.extract(@pkg_no_engines)
    end
  end

  describe "node_range" do
    test "returns node constraint" do
      assert ">=18" = NPM.Engines.node_range(@pkg_with_engines)
    end

    test "nil when not specified" do
      assert nil == NPM.Engines.node_range(@pkg_no_engines)
    end
  end

  describe "npm_range" do
    test "returns npm constraint" do
      assert ">=9" = NPM.Engines.npm_range(@pkg_with_engines)
    end

    test "nil when not specified" do
      assert nil == NPM.Engines.npm_range(@pkg_no_engines)
    end
  end

  describe "has_engines?" do
    test "true when engines present" do
      assert NPM.Engines.has_engines?(@pkg_with_engines)
    end

    test "false when no engines" do
      refute NPM.Engines.has_engines?(@pkg_no_engines)
    end
  end

  describe "strictest_node" do
    test "combines node ranges" do
      packages = [
        %{"engines" => %{"node" => ">=16"}},
        %{"engines" => %{"node" => ">=18"}}
      ]

      result = NPM.Engines.strictest_node(packages)
      assert result =~ ">=16"
      assert result =~ ">=18"
    end

    test "nil when no node ranges" do
      assert nil == NPM.Engines.strictest_node([@pkg_no_engines])
    end
  end

  describe "used_engines" do
    test "collects unique engine names" do
      packages = [
        %{"engines" => %{"node" => ">=16", "npm" => ">=7"}},
        %{"engines" => %{"node" => ">=18", "yarn" => ">=3"}}
      ]

      engines = NPM.Engines.used_engines(packages)
      assert "node" in engines
      assert "npm" in engines
      assert "yarn" in engines
    end

    test "empty when no engines" do
      assert [] = NPM.Engines.used_engines([@pkg_no_engines])
    end
  end

  describe "unknown_engines" do
    test "detects non-standard engines" do
      data = %{"engines" => %{"node" => ">=18", "vscode" => "^1.75"}}
      assert ["vscode"] = NPM.Engines.unknown_engines(data)
    end

    test "empty for standard engines" do
      assert [] = NPM.Engines.unknown_engines(@pkg_with_engines)
    end
  end

  describe "summary" do
    test "summarizes engine usage" do
      packages = [@pkg_with_engines, @pkg_no_engines, %{"engines" => %{"node" => ">=20"}}]
      sum = NPM.Engines.summary(packages)
      assert sum.total_packages == 3
      assert sum.with_engines == 2
      assert sum.without_engines == 1
      assert "node" in sum.engines_used
    end
  end
end
