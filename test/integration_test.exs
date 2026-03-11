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

  describe "full install" do
    @tag :tmp_dir
    test "install writes lockfile and fetches tarball", %{tmp_dir: dir} do
      pkg_path = Path.join(dir, "package.json")
      lock_path = Path.join(dir, "npm.lock")
      deps_dir = Path.join(dir, "deps/npm")

      File.write!(pkg_path, ~s({"dependencies": {"is-number": "^7.0.0"}}))

      # Temporarily override paths
      {:ok, deps} = NPM.PackageJson.read(pkg_path)
      NPM.Resolver.clear_cache()
      {:ok, resolved} = NPM.Resolver.resolve(deps)

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

      NPM.Lockfile.write(lockfile, lock_path)

      assert {:ok, read_lock} = NPM.Lockfile.read(lock_path)
      assert read_lock["is-number"].version =~ ~r/^7\./

      entry = read_lock["is-number"]
      dest = Path.join(deps_dir, "is-number")
      assert {:ok, _count} = NPM.Tarball.fetch_and_extract(entry.tarball, entry.integrity, dest)
      assert File.exists?(Path.join(dest, "package.json"))
    end
  end
end
