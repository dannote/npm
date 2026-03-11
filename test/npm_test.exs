defmodule NPMTest do
  use ExUnit.Case, async: true

  describe "PackageJson" do
    @tag :tmp_dir
    test "read returns empty deps for missing file", %{tmp_dir: dir} do
      assert {:ok, %{}} = NPM.PackageJson.read(Path.join(dir, "package.json"))
    end

    @tag :tmp_dir
    test "add_dep creates file and reads back", %{tmp_dir: dir} do
      path = Path.join(dir, "package.json")

      assert :ok = NPM.PackageJson.add_dep("lodash", "^4.17.0", path)
      assert {:ok, %{"lodash" => "^4.17.0"}} = NPM.PackageJson.read(path)
    end

    @tag :tmp_dir
    test "add_dep preserves existing deps", %{tmp_dir: dir} do
      path = Path.join(dir, "package.json")

      NPM.PackageJson.add_dep("lodash", "^4.17.0", path)
      NPM.PackageJson.add_dep("express", "^5.0.0", path)

      assert {:ok, deps} = NPM.PackageJson.read(path)
      assert deps["lodash"] == "^4.17.0"
      assert deps["express"] == "^5.0.0"
    end
  end

  describe "Lockfile" do
    @tag :tmp_dir
    test "read returns empty map for missing file", %{tmp_dir: dir} do
      assert {:ok, %{}} = NPM.Lockfile.read(Path.join(dir, "npm.lock"))
    end

    @tag :tmp_dir
    test "write and read round-trips", %{tmp_dir: dir} do
      path = Path.join(dir, "npm.lock")

      lockfile = %{
        "lodash" => %{
          version: "4.17.21",
          integrity: "sha512-abc123==",
          tarball: "https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz",
          dependencies: %{}
        }
      }

      assert :ok = NPM.Lockfile.write(lockfile, path)
      assert {:ok, read_back} = NPM.Lockfile.read(path)
      assert read_back["lodash"].version == "4.17.21"
      assert read_back["lodash"].integrity == "sha512-abc123=="
    end
  end

  describe "JSON" do
    test "encode_pretty produces sorted keys" do
      json = NPM.JSON.encode_pretty(%{"b" => 1, "a" => 2})
      assert json =~ ~r/"a": 2.*"b": 1/s
    end
  end

  describe "Tarball" do
    test "verify_integrity passes for correct sha512" do
      data = "hello world"
      hash = :crypto.hash(:sha512, data) |> Base.encode64()
      assert :ok = NPM.Tarball.verify_integrity(data, "sha512-#{hash}")
    end

    test "verify_integrity fails for wrong hash" do
      assert {:error, :integrity_mismatch} =
               NPM.Tarball.verify_integrity("hello", "sha512-wronghash==")
    end

    test "verify_integrity passes for empty string" do
      assert :ok = NPM.Tarball.verify_integrity("anything", "")
    end

    @tag :tmp_dir
    test "extract unpacks tgz and strips package/ prefix", %{tmp_dir: dir} do
      tgz = create_test_tgz(%{"package/index.js" => "module.exports = 42;"})

      assert {:ok, 1} = NPM.Tarball.extract(tgz, dir)
      assert File.read!(Path.join(dir, "index.js")) == "module.exports = 42;"
    end
  end

  defp create_test_tgz(files) do
    tmp = System.tmp_dir!()
    tgz_path = Path.join(tmp, "npm_test_#{System.unique_integer([:positive])}.tgz")

    file_entries =
      Enum.map(files, fn {name, content} ->
        path = Path.join(tmp, name)
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, content)
        {~c"#{name}", ~c"#{path}"}
      end)

    :ok = :erl_tar.create(~c"#{tgz_path}", file_entries, [:compressed])
    data = File.read!(tgz_path)

    File.rm!(tgz_path)
    Enum.each(files, fn {name, _} -> File.rm(Path.join(tmp, name)) end)

    data
  end
end
