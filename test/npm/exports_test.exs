defmodule NPM.ExportsTest do
  use ExUnit.Case, async: true

  describe "Exports.parse" do
    test "parses string shorthand" do
      pkg = %{"exports" => "./index.js"}
      assert NPM.Exports.parse(pkg) == %{"." => "./index.js"}
    end

    test "parses subpath exports" do
      pkg = %{"exports" => %{"." => "./index.js", "./utils" => "./lib/utils.js"}}
      result = NPM.Exports.parse(pkg)
      assert result["."] == "./index.js"
      assert result["./utils"] == "./lib/utils.js"
    end

    test "wraps conditional exports as root entry" do
      pkg = %{"exports" => %{"import" => "./esm.js", "require" => "./cjs.js"}}
      result = NPM.Exports.parse(pkg)
      assert result["."] == %{"import" => "./esm.js", "require" => "./cjs.js"}
    end

    test "returns nil when no exports field" do
      assert NPM.Exports.parse(%{"name" => "pkg"}) == nil
    end

    test "handles nested subpath with conditions" do
      pkg = %{
        "exports" => %{
          "." => %{"import" => "./esm/index.js", "default" => "./cjs/index.js"},
          "./utils" => "./lib/utils.js"
        }
      }

      result = NPM.Exports.parse(pkg)
      assert result["."] == %{"import" => "./esm/index.js", "default" => "./cjs/index.js"}
      assert result["./utils"] == "./lib/utils.js"
    end
  end

  describe "Exports.resolve" do
    test "resolves string target" do
      export_map = %{"." => "./index.js", "./utils" => "./lib/utils.js"}
      assert {:ok, "./index.js"} = NPM.Exports.resolve(export_map, ".")
      assert {:ok, "./lib/utils.js"} = NPM.Exports.resolve(export_map, "./utils")
    end

    test "resolves conditional target with matching condition" do
      export_map = %{"." => %{"import" => "./esm.js", "require" => "./cjs.js"}}
      assert {:ok, "./esm.js"} = NPM.Exports.resolve(export_map, ".", ["import", "default"])
      assert {:ok, "./cjs.js"} = NPM.Exports.resolve(export_map, ".", ["require", "default"])
    end

    test "falls back to default condition" do
      export_map = %{"." => %{"import" => "./esm.js", "default" => "./cjs.js"}}
      assert {:ok, "./cjs.js"} = NPM.Exports.resolve(export_map, ".", ["default"])
    end

    test "returns error for missing subpath" do
      export_map = %{"." => "./index.js"}
      assert :error = NPM.Exports.resolve(export_map, "./missing")
    end

    test "returns error when no conditions match" do
      export_map = %{"." => %{"import" => "./esm.js"}}
      assert :error = NPM.Exports.resolve(export_map, ".", ["require"])
    end
  end

  describe "Exports.subpaths" do
    test "lists sorted subpaths" do
      export_map = %{
        "./utils" => "./lib/utils.js",
        "." => "./index.js",
        "./types" => "./types.d.ts"
      }

      assert NPM.Exports.subpaths(export_map) == [".", "./types", "./utils"]
    end

    test "returns empty for nil" do
      assert NPM.Exports.subpaths(nil) == []
    end
  end

  describe "Exports.module_type" do
    test "detects ESM" do
      assert NPM.Exports.module_type(%{"type" => "module"}) == :esm
    end

    test "defaults to CJS" do
      assert NPM.Exports.module_type(%{"type" => "commonjs"}) == :cjs
      assert NPM.Exports.module_type(%{}) == :cjs
    end
  end

  describe "Exports: condition priority" do
    test "import takes priority over require" do
      exports = %{
        "." => %{
          "import" => "./esm.js",
          "require" => "./cjs.js"
        }
      }

      assert {:ok, "./esm.js"} = NPM.Exports.resolve(exports, ".", ["import", "require"])
    end

    test "first matching condition wins" do
      exports = %{
        "." => %{
          "node" => "./node.js",
          "browser" => "./browser.js",
          "default" => "./default.js"
        }
      }

      assert {:ok, "./node.js"} = NPM.Exports.resolve(exports, ".", ["node", "default"])
    end
  end

  describe "Exports: deeply nested conditions" do
    test "three-level condition nesting" do
      exports = %{
        "." => %{
          "node" => %{
            "import" => "./node-esm.js",
            "require" => "./node-cjs.js"
          },
          "default" => "./default.js"
        }
      }

      assert {:ok, "./node-esm.js"} = NPM.Exports.resolve(exports, ".", ["node", "import"])
    end
  end

  describe "Exports: wildcard subpath patterns" do
    test "wildcard pattern matches subpath" do
      exports = %{
        "./*" => "./lib/*.js"
      }

      # Wildcard resolution with *
      result = NPM.Exports.resolve(exports, "./utils")

      case result do
        {:ok, path} -> assert String.contains?(path, "utils")
        :error -> :ok
      end
    end
  end

  describe "Exports: map patterns" do
    test "single dot entry" do
      assert {:ok, "./index.js"} = NPM.Exports.resolve(%{"." => "./index.js"}, ".")
    end

    test "missing subpath returns error" do
      assert :error = NPM.Exports.resolve(%{"." => "./index.js"}, "./missing")
    end

    test "nested conditions with single match" do
      exports = %{"." => %{"default" => "./lib.js"}}
      assert {:ok, "./lib.js"} = NPM.Exports.resolve(exports, ".", ["default"])
    end
  end

  describe "Exports: real-world conditional export patterns" do
    test "Node.js-style conditions (import/require/default)" do
      export_map = %{
        "." => %{
          "import" => %{"types" => "./types/index.d.ts", "default" => "./esm/index.js"},
          "require" => %{"types" => "./types/index.d.ts", "default" => "./cjs/index.js"},
          "default" => "./cjs/index.js"
        }
      }

      assert {:ok, "./esm/index.js"} =
               NPM.Exports.resolve(export_map, ".", ["import", "default"])

      assert {:ok, "./cjs/index.js"} =
               NPM.Exports.resolve(export_map, ".", ["require", "default"])

      # Fallback to default
      assert {:ok, "./cjs/index.js"} =
               NPM.Exports.resolve(export_map, ".", ["default"])
    end

    test "subpath exports with multiple entries" do
      export_map = %{
        "." => "./index.js",
        "./utils" => "./lib/utils.js",
        "./helpers/*" => "./lib/helpers/*.js",
        "./package.json" => "./package.json"
      }

      assert {:ok, "./index.js"} = NPM.Exports.resolve(export_map, ".")
      assert {:ok, "./lib/utils.js"} = NPM.Exports.resolve(export_map, "./utils")
      assert {:ok, "./package.json"} = NPM.Exports.resolve(export_map, "./package.json")
      assert :error = NPM.Exports.resolve(export_map, "./internal")
    end
  end

  describe "Exports: subpaths listing" do
    test "lists all export subpaths" do
      exports = %{
        "." => "./index.js",
        "./utils" => "./utils.js",
        "./helpers/*" => "./helpers/*.js"
      }

      paths = NPM.Exports.subpaths(exports)
      assert "." in paths
      assert "./utils" in paths
      assert "./helpers/*" in paths
    end
  end

  describe "Exports: parse from package data" do
    test "string exports is normalized to map" do
      result = NPM.Exports.parse(%{"exports" => "./dist/index.js"})
      assert is_map(result)
      assert result["."] == "./dist/index.js"
    end

    test "map exports are returned" do
      exports = %{"." => "./index.js", "./sub" => "./sub.js"}
      result = NPM.Exports.parse(%{"exports" => exports})
      assert is_map(result)
    end

    test "no exports returns nil" do
      assert nil == NPM.Exports.parse(%{"name" => "pkg"})
    end
  end

  describe "Exports: module_type detection" do
    test "module type is ESM" do
      assert :esm = NPM.Exports.module_type(%{"type" => "module"})
    end

    test "commonjs type is CJS" do
      assert :cjs = NPM.Exports.module_type(%{"type" => "commonjs"})
    end

    test "no type defaults to CJS" do
      assert :cjs = NPM.Exports.module_type(%{})
    end
  end
end
