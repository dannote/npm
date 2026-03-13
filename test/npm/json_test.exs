defmodule NPM.JsonTest do
  use ExUnit.Case, async: true

  describe "JSON.encode_pretty" do
    test "produces sorted keys" do
      json = NPM.JSON.encode_pretty(%{"b" => 1, "a" => 2})
      assert json =~ ~r/"a": 2.*"b": 1/s
    end

    test "handles nested maps" do
      json = NPM.JSON.encode_pretty(%{"outer" => %{"z" => 1, "a" => 2}})
      assert json =~ "outer"
      assert json =~ ~r/"a": 2.*"z": 1/s
    end

    test "handles empty map" do
      assert NPM.JSON.encode_pretty(%{}) == "{}\n"
    end
  end

  describe "JSON.encode_pretty complex" do
    test "sorts nested map keys at all levels" do
      data = %{
        "z" => %{"b" => 1, "a" => 2},
        "a" => %{"d" => 3, "c" => 4}
      }

      json = NPM.JSON.encode_pretty(data)
      a_pos = :binary.match(json, ~s("a")) |> elem(0)
      z_pos = :binary.match(json, ~s("z")) |> elem(0)
      assert a_pos < z_pos
    end

    test "handles deeply nested structures" do
      data = %{"l1" => %{"l2" => %{"l3" => "deep"}}}
      json = NPM.JSON.encode_pretty(data)
      assert json =~ "deep"
      assert json =~ "l1"
      assert json =~ "l2"
      assert json =~ "l3"
    end

    test "handles mixed arrays and maps" do
      data = %{"items" => [%{"name" => "a"}, %{"name" => "b"}]}
      json = NPM.JSON.encode_pretty(data)
      assert json =~ ~s("name": "a")
      assert json =~ ~s("name": "b")
    end

    test "produces valid JSON" do
      data = %{
        "name" => "test",
        "version" => "1.0.0",
        "dependencies" => %{"a" => "^1.0", "b" => "^2.0"},
        "scripts" => %{"test" => "jest"}
      }

      json = NPM.JSON.encode_pretty(data)
      decoded = :json.decode(json)
      assert decoded["name"] == "test"
      assert decoded["dependencies"]["a"] == "^1.0"
    end
  end

  describe "JSON.encode_pretty edge cases" do
    test "handles lists" do
      json = NPM.JSON.encode_pretty(%{"items" => [1, 2, 3]})
      assert json =~ "items"
      assert json =~ "1"
    end

    test "handles nested lists in maps" do
      json = NPM.JSON.encode_pretty(%{"files" => ["a.js", "b.js"]})
      assert json =~ ~s("a.js")
      assert json =~ ~s("b.js")
    end

    test "handles boolean values" do
      json = NPM.JSON.encode_pretty(%{"private" => true})
      assert json =~ "true"
    end

    test "handles empty list" do
      json = NPM.JSON.encode_pretty(%{"items" => []})
      assert json =~ "[]"
    end

    test "handles integer values" do
      json = NPM.JSON.encode_pretty(%{"count" => 42})
      assert json =~ "42"
    end
  end

  describe "JSON encode/decode roundtrip" do
    test "package.json style document" do
      original = %{
        "name" => "test-pkg",
        "version" => "1.0.0",
        "dependencies" => %{"a" => "^1.0", "b" => "~2.0"},
        "devDependencies" => %{"c" => "^3.0"},
        "scripts" => %{"test" => "jest"}
      }

      json = NPM.JSON.encode_pretty(original)
      decoded = :json.decode(json)

      assert decoded["name"] == original["name"]
      assert decoded["dependencies"] == original["dependencies"]
      assert decoded["devDependencies"] == original["devDependencies"]
      assert decoded["scripts"] == original["scripts"]
    end
  end

  describe "JSON.encode_pretty indentation" do
    test "uses two-space indentation" do
      json = NPM.JSON.encode_pretty(%{"a" => 1})
      assert json == "{\n  \"a\": 1\n}\n"
    end

    test "nested maps use correct indentation" do
      json = NPM.JSON.encode_pretty(%{"outer" => %{"inner" => 1}})
      assert json =~ "  \"outer\": {\n    \"inner\": 1\n  }"
    end

    test "trailing newline" do
      json = NPM.JSON.encode_pretty(%{})
      assert String.ends_with?(json, "\n")
    end
  end
end
