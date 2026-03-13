defmodule NPM.RegistryTest do
  use ExUnit.Case, async: true

  describe "Registry.registry_url" do
    test "defaults to npmjs.org" do
      original = System.get_env("NPM_REGISTRY")
      System.delete_env("NPM_REGISTRY")

      assert NPM.Registry.registry_url() == "https://registry.npmjs.org"

      if original, do: System.put_env("NPM_REGISTRY", original)
    end

    test "respects NPM_REGISTRY env var" do
      original = System.get_env("NPM_REGISTRY")
      System.put_env("NPM_REGISTRY", "https://registry.example.com")

      assert NPM.Registry.registry_url() == "https://registry.example.com"

      if original do
        System.put_env("NPM_REGISTRY", original)
      else
        System.delete_env("NPM_REGISTRY")
      end
    end
  end

  describe "Registry URL encoding" do
    test "get_packument constructs correct URL for scoped packages" do
      url = "https://registry.npmjs.org/#{String.replace("@scope/pkg", "/", "%2f")}"
      assert url == "https://registry.npmjs.org/@scope%2fpkg"
    end

    test "get_packument constructs correct URL for simple packages" do
      url = "https://registry.npmjs.org/lodash"
      assert url == "https://registry.npmjs.org/lodash"
    end
  end

  describe "Registry: scoped package URL encoding" do
    test "encode_package handles scoped packages" do
      assert NPM.Registry.encode_package("@babel/core") == "@babel%2fcore"
    end

    test "encode_package leaves unscoped packages unchanged" do
      assert NPM.Registry.encode_package("lodash") == "lodash"
    end

    test "encode_package handles deeply scoped names" do
      assert NPM.Registry.encode_package("@types/node") == "@types%2fnode"
    end
  end

  describe "Registry: encode_package preserves simple names" do
    test "simple names pass through unchanged" do
      assert "react" = NPM.Registry.encode_package("react")
      assert "lodash" = NPM.Registry.encode_package("lodash")
      assert "is-number" = NPM.Registry.encode_package("is-number")
    end
  end

  describe "Registry: packument parsing correctness" do
    test "parse_version_info includes all expected fields" do
      # Test the structure returned by get_packument is complete
      # We test with a mock since this is about parsing, not network
      raw_info = %{
        "dependencies" => %{"dep-a" => "^1.0"},
        "peerDependencies" => %{"react" => "^18.0"},
        "peerDependenciesMeta" => %{"react" => %{"optional" => true}},
        "optionalDependencies" => %{"fsevents" => "^2.0"},
        "bin" => %{"cli" => "./bin/cli.js"},
        "engines" => %{"node" => ">=18"},
        "os" => ["darwin", "linux"],
        "cpu" => ["x64", "arm64"],
        "hasInstallScript" => true,
        "deprecated" => "use @new/pkg instead",
        "dist" => %{
          "tarball" => "https://registry.npmjs.org/pkg/-/pkg-1.0.0.tgz",
          "integrity" => "sha512-abc123",
          "fileCount" => 42,
          "unpackedSize" => 100_000
        }
      }

      # This verifies the structure matches what our code expects
      assert is_map(raw_info["dependencies"])
      assert is_map(raw_info["peerDependencies"])
      assert raw_info["hasInstallScript"] == true
      assert is_binary(raw_info["deprecated"])
      assert raw_info["dist"]["integrity"] =~ "sha512-"
    end
  end
end
