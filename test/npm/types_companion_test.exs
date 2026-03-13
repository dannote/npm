defmodule NPM.TypesCompanionTest do
  use ExUnit.Case, async: true

  describe "suggest" do
    test "suggests types for untyped deps" do
      data = %{"dependencies" => %{"express" => "^4.18", "lodash" => "^4.17"}}
      suggestions = NPM.TypesCompanion.suggest(data)
      names = Enum.map(suggestions, & &1.types_package)
      assert "@types/express" in names
      assert "@types/lodash" in names
    end

    test "skips already installed types" do
      data = %{
        "dependencies" => %{"express" => "^4.18"},
        "devDependencies" => %{"@types/express" => "^4.17"}
      }

      suggestions = NPM.TypesCompanion.suggest(data)
      refute Enum.any?(suggestions, &(&1.types_package == "@types/express"))
    end

    test "skips packages with own types" do
      data = %{"dependencies" => %{"axios" => "^1.0"}}
      suggestions = NPM.TypesCompanion.suggest(data)
      refute Enum.any?(suggestions, &(&1.package == "axios"))
    end

    test "empty for no deps" do
      assert [] = NPM.TypesCompanion.suggest(%{})
    end
  end

  describe "types_package" do
    test "regular package" do
      assert "@types/lodash" = NPM.TypesCompanion.types_package("lodash")
    end

    test "scoped package" do
      assert "@types/babel__core" = NPM.TypesCompanion.types_package("@babel/core")
    end
  end

  describe "has_own_types?" do
    test "true for types field" do
      assert NPM.TypesCompanion.has_own_types?(%{"types" => "./index.d.ts"})
    end

    test "true for typings field" do
      assert NPM.TypesCompanion.has_own_types?(%{"typings" => "./index.d.ts"})
    end

    test "false without types" do
      refute NPM.TypesCompanion.has_own_types?(%{"name" => "express"})
    end
  end

  describe "orphaned_types" do
    test "detects orphaned @types packages" do
      data = %{
        "dependencies" => %{"react" => "^18.0"},
        "devDependencies" => %{"@types/react" => "^18.0", "@types/lodash" => "^4.14"}
      }

      orphans = NPM.TypesCompanion.orphaned_types(data)
      assert "@types/lodash" in orphans
      refute "@types/react" in orphans
    end

    test "empty when all have companions" do
      data = %{
        "dependencies" => %{"react" => "^18.0"},
        "devDependencies" => %{"@types/react" => "^18.0"}
      }

      assert [] = NPM.TypesCompanion.orphaned_types(data)
    end
  end
end
