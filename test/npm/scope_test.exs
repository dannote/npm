defmodule NPM.ScopeTest do
  use ExUnit.Case, async: true

  describe "scoped?" do
    test "true for scoped package" do
      assert NPM.Scope.scoped?("@babel/core")
    end

    test "false for unscoped package" do
      refute NPM.Scope.scoped?("lodash")
    end

    test "false for bare @ without slash" do
      refute NPM.Scope.scoped?("@standalone")
    end
  end

  describe "extract" do
    test "extracts scope" do
      assert "babel" = NPM.Scope.extract("@babel/core")
    end

    test "nil for unscoped" do
      assert nil == NPM.Scope.extract("lodash")
    end

    test "extracts from deeply scoped" do
      assert "types" = NPM.Scope.extract("@types/node")
    end
  end

  describe "bare_name" do
    test "returns name without scope" do
      assert "core" = NPM.Scope.bare_name("@babel/core")
    end

    test "returns name as-is for unscoped" do
      assert "lodash" = NPM.Scope.bare_name("lodash")
    end
  end

  describe "full_name" do
    test "constructs scoped name" do
      assert "@babel/core" = NPM.Scope.full_name("babel", "core")
    end
  end

  describe "valid_scope?" do
    test "valid lowercase scope" do
      assert NPM.Scope.valid_scope?("myorg")
    end

    test "valid scope with hyphens" do
      assert NPM.Scope.valid_scope?("my-org")
    end

    test "invalid with uppercase" do
      refute NPM.Scope.valid_scope?("MyOrg")
    end

    test "invalid starting with dot" do
      refute NPM.Scope.valid_scope?(".hidden")
    end

    test "invalid starting with number" do
      refute NPM.Scope.valid_scope?("1org")
    end
  end

  describe "valid_name?" do
    test "valid unscoped name" do
      assert NPM.Scope.valid_name?("lodash")
    end

    test "valid scoped name" do
      assert NPM.Scope.valid_name?("@babel/core")
    end

    test "invalid empty name" do
      refute NPM.Scope.valid_name?("")
    end

    test "invalid uppercase" do
      refute NPM.Scope.valid_name?("MyPackage")
    end

    test "valid name with dots" do
      assert NPM.Scope.valid_name?("lodash.get")
    end
  end

  describe "unique_scopes" do
    test "extracts unique scopes" do
      names = ["@babel/core", "@babel/parser", "@types/node", "lodash"]
      scopes = NPM.Scope.unique_scopes(names)
      assert scopes == ["babel", "types"]
    end

    test "empty for no scoped packages" do
      assert [] = NPM.Scope.unique_scopes(["lodash", "react"])
    end
  end

  describe "group_by_scope" do
    test "groups by scope" do
      names = ["@babel/core", "@babel/parser", "lodash"]
      groups = NPM.Scope.group_by_scope(names)
      assert length(groups["babel"]) == 2
      assert length(groups[nil]) == 1
    end
  end
end
