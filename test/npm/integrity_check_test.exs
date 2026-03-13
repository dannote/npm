defmodule NPM.IntegrityCheckTest do
  use ExUnit.Case, async: true

  describe "verify_package" do
    @tag :tmp_dir
    test "ok when version matches", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "lodash")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), ~s({"name":"lodash","version":"4.17.21"}))

      entry = %{version: "4.17.21"}
      assert :ok = NPM.IntegrityCheck.verify_package("lodash", entry, nm)
    end

    @tag :tmp_dir
    test "version mismatch", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "lodash")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), ~s({"name":"lodash","version":"4.17.20"}))

      entry = %{version: "4.17.21"}
      assert {:error, :version_mismatch} = NPM.IntegrityCheck.verify_package("lodash", entry, nm)
    end

    @tag :tmp_dir
    test "not installed", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(nm)

      entry = %{version: "4.17.21"}
      assert {:error, :not_installed} = NPM.IntegrityCheck.verify_package("missing", entry, nm)
    end

    @tag :tmp_dir
    test "invalid package.json", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "broken")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), "not json")

      entry = %{version: "1.0.0"}

      assert {:error, :invalid_package_json} =
               NPM.IntegrityCheck.verify_package("broken", entry, nm)
    end
  end

  describe "verify_all" do
    @tag :tmp_dir
    test "returns failures", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(nm)

      lockfile = %{
        "missing-pkg" => %{version: "1.0.0"}
      }

      failures = NPM.IntegrityCheck.verify_all(lockfile, nm)
      assert length(failures) == 1
      assert hd(failures).reason == :not_installed
    end

    @tag :tmp_dir
    test "empty when all valid", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "ok-pkg")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), ~s({"version":"1.0.0"}))

      assert [] = NPM.IntegrityCheck.verify_all(%{"ok-pkg" => %{version: "1.0.0"}}, nm)
    end
  end

  describe "group_failures" do
    test "groups by reason" do
      failures = [
        %{name: "a", reason: :not_installed},
        %{name: "b", reason: :not_installed},
        %{name: "c", reason: :version_mismatch}
      ]

      grouped = NPM.IntegrityCheck.group_failures(failures)
      assert length(grouped[:not_installed]) == 2
      assert length(grouped[:version_mismatch]) == 1
    end
  end

  describe "format_results" do
    test "all verified" do
      assert "All packages verified." = NPM.IntegrityCheck.format_results([])
    end

    test "formats failures" do
      failures = [%{name: "pkg-a", reason: :not_installed}]
      formatted = NPM.IntegrityCheck.format_results(failures)
      assert formatted =~ "not_installed: pkg-a"
    end
  end
end
