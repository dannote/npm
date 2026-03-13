defmodule NPM.SideEffectsTest do
  use ExUnit.Case, async: true

  describe "get" do
    test "false value" do
      assert false == NPM.SideEffects.get(%{"sideEffects" => false})
    end

    test "array value" do
      assert ["./src/polyfill.js"] =
               NPM.SideEffects.get(%{"sideEffects" => ["./src/polyfill.js"]})
    end

    test "nil when not set" do
      assert nil == NPM.SideEffects.get(%{})
    end
  end

  describe "tree_shakeable?" do
    test "true for false value" do
      assert NPM.SideEffects.tree_shakeable?(%{"sideEffects" => false})
    end

    test "false for array" do
      refute NPM.SideEffects.tree_shakeable?(%{"sideEffects" => ["file.js"]})
    end

    test "false for not set" do
      refute NPM.SideEffects.tree_shakeable?(%{})
    end
  end

  describe "has_side_effects?" do
    test "false when sideEffects is false" do
      refute NPM.SideEffects.has_side_effects?(%{"sideEffects" => false})
    end

    test "false when empty array" do
      refute NPM.SideEffects.has_side_effects?(%{"sideEffects" => []})
    end

    test "true when not declared" do
      assert NPM.SideEffects.has_side_effects?(%{})
    end
  end

  describe "files_with_side_effects" do
    test "returns array patterns" do
      data = %{"sideEffects" => ["./src/polyfill.js", "*.css"]}
      assert length(NPM.SideEffects.files_with_side_effects(data)) == 2
    end

    test "empty for non-array" do
      assert [] = NPM.SideEffects.files_with_side_effects(%{"sideEffects" => false})
    end
  end

  describe "file_has_side_effects?" do
    test "false when all tree-shakeable" do
      data = %{"sideEffects" => false}
      refute NPM.SideEffects.file_has_side_effects?("any.js", data)
    end

    test "true for matching glob pattern" do
      data = %{"sideEffects" => ["*.css"]}
      assert NPM.SideEffects.file_has_side_effects?("styles.css", data)
    end

    test "false for non-matching file" do
      data = %{"sideEffects" => ["*.css"]}
      refute NPM.SideEffects.file_has_side_effects?("utils.js", data)
    end

    test "exact file match" do
      data = %{"sideEffects" => ["./polyfill.js"]}
      assert NPM.SideEffects.file_has_side_effects?("./polyfill.js", data)
    end

    test "true when field not set" do
      assert NPM.SideEffects.file_has_side_effects?("any.js", %{})
    end
  end

  describe "stats" do
    test "counts tree-shakeable packages" do
      packages = [
        %{"sideEffects" => false},
        %{"sideEffects" => ["*.css"]},
        %{"name" => "no-info"}
      ]

      stats = NPM.SideEffects.stats(packages)
      assert stats.tree_shakeable == 1
      assert stats.partial == 1
      assert stats.unknown == 1
    end
  end
end
