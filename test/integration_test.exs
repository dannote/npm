defmodule NPM.IntegrationTest do
  use ExUnit.Case

  @moduletag :integration

  describe "Registry" do
    test "fetches lodash packument" do
      assert {:ok, packument} = NPM.Registry.get_packument("lodash")
      assert packument.name == "lodash"
      assert Map.has_key?(packument.versions, "4.17.21")
    end

    test "fetches scoped package" do
      assert {:ok, packument} = NPM.Registry.get_packument("@types/node")
      assert packument.name == "@types/node"
      assert map_size(packument.versions) > 0
    end

    test "returns error for nonexistent package" do
      assert {:error, :not_found} =
               NPM.Registry.get_packument("this-package-does-not-exist-xyz-123")
    end
  end

  describe "Resolver" do
    test "resolves a single package" do
      assert {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "^7.0.0"})
      assert resolved["is-number"] =~ ~r/^7\./
    end

    test "resolves package with dependencies" do
      assert {:ok, resolved} = NPM.Resolver.resolve(%{"depd" => "^2.0.0"})
      assert resolved["depd"] =~ ~r/^2\./
    end
  end

  describe "full install with cache + node_modules" do
    @tag :tmp_dir
    test "installs package into cache and links to node_modules", %{tmp_dir: dir} do
      cache_dir = Path.join(dir, "npm_cache")
      nm_dir = Path.join(dir, "node_modules")
      System.put_env("NPM_EX_CACHE_DIR", cache_dir)

      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(%{"is-number" => "^7.0.0"})

      lockfile =
        for {name, version_str} <- resolved, into: %{} do
          {:ok, packument} = NPM.Registry.get_packument(name)
          info = Map.fetch!(packument.versions, version_str)

          {name,
           %{
             version: version_str,
             integrity: info.dist.integrity,
             tarball: info.dist.tarball,
             dependencies: info.dependencies
           }}
        end

      assert :ok = NPM.Linker.link(lockfile, nm_dir)

      # Package in cache
      assert NPM.Cache.cached?("is-number", lockfile["is-number"].version)

      # node_modules linked
      assert File.exists?(Path.join([nm_dir, "is-number", "package.json"]))

      System.delete_env("NPM_EX_CACHE_DIR")
    end
  end
end
