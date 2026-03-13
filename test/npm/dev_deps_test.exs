defmodule NPM.DevDepsTest do
  use ExUnit.Case, async: true

  @pkg_data %{
    "dependencies" => %{"react" => "^18.0.0", "express" => "^4.0.0"},
    "devDependencies" => %{"jest" => "^29.0.0", "typescript" => "^5.0.0", "eslint" => "^8.0.0"}
  }

  describe "extract" do
    test "extracts dev dependencies" do
      deps = NPM.DevDeps.extract(@pkg_data)
      assert map_size(deps) == 3
      assert deps["jest"] == "^29.0.0"
    end

    test "empty when no dev deps" do
      assert %{} = NPM.DevDeps.extract(%{"dependencies" => %{}})
    end
  end

  describe "production_deps" do
    test "returns only production deps" do
      prod = NPM.DevDeps.production_deps(@pkg_data)
      assert map_size(prod) == 2
      assert prod["react"] == "^18.0.0"
      refute Map.has_key?(prod, "jest")
    end
  end

  describe "all_deps" do
    test "merges production and dev deps" do
      all = NPM.DevDeps.all_deps(@pkg_data)
      assert map_size(all) == 5
      assert Map.has_key?(all, "react")
      assert Map.has_key?(all, "jest")
    end
  end

  describe "dev_dep?" do
    test "true for dev dependency" do
      assert NPM.DevDeps.dev_dep?("jest", @pkg_data)
    end

    test "false for production dependency" do
      refute NPM.DevDeps.dev_dep?("react", @pkg_data)
    end

    test "false for unknown package" do
      refute NPM.DevDeps.dev_dep?("unknown", @pkg_data)
    end
  end

  describe "categorize" do
    test "separates prod and dev" do
      cat = NPM.DevDeps.categorize(@pkg_data)
      assert map_size(cat.production) == 2
      assert map_size(cat.development) == 3
    end
  end

  describe "overlapping" do
    test "finds deps in both prod and dev" do
      data = %{
        "dependencies" => %{"lodash" => "^4.0.0"},
        "devDependencies" => %{"lodash" => "^4.17.0", "jest" => "^29.0.0"}
      }

      overlaps = NPM.DevDeps.overlapping(data)
      assert "lodash" in overlaps
      refute "jest" in overlaps
    end

    test "empty when no overlap" do
      assert [] = NPM.DevDeps.overlapping(@pkg_data)
    end
  end

  describe "summary" do
    test "counts by category" do
      s = NPM.DevDeps.summary(@pkg_data)
      assert s.production == 2
      assert s.development == 3
      assert s.total == 5
    end

    test "empty package" do
      s = NPM.DevDeps.summary(%{})
      assert s.total == 0
    end
  end

  describe "extract with no devDependencies key" do
    test "returns empty map" do
      assert %{} = NPM.DevDeps.extract(%{"name" => "pkg"})
    end
  end

  describe "all_deps with only dev deps" do
    test "returns just dev deps" do
      data = %{"devDependencies" => %{"jest" => "^29"}}
      all = NPM.DevDeps.all_deps(data)
      assert all == %{"jest" => "^29"}
    end
  end
end
