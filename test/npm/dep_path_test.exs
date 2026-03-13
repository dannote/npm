defmodule NPM.DepPathTest do
  use ExUnit.Case, async: true

  describe "resolve" do
    test "unscoped package" do
      assert "node_modules/lodash" = NPM.DepPath.resolve("lodash")
    end

    test "scoped package" do
      assert "node_modules/@babel/core" = NPM.DepPath.resolve("@babel/core")
    end

    test "custom node_modules" do
      assert "deps/lodash" = NPM.DepPath.resolve("lodash", "deps")
    end
  end

  describe "nested" do
    test "nested dependency" do
      assert "node_modules/express/node_modules/debug" = NPM.DepPath.nested("express", "debug")
    end
  end

  describe "bin_dir" do
    test "default bin dir" do
      assert "node_modules/.bin" = NPM.DepPath.bin_dir()
    end
  end

  describe "bin_path" do
    test "command path" do
      assert "node_modules/.bin/eslint" = NPM.DepPath.bin_path("eslint")
    end
  end

  describe "package_json" do
    test "package.json path" do
      assert "node_modules/lodash/package.json" = NPM.DepPath.package_json("lodash")
    end
  end

  describe "exists?" do
    @tag :tmp_dir
    test "true when package exists", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "my-pkg")
      File.mkdir_p!(pkg)
      File.write!(Path.join(pkg, "package.json"), "{}")
      assert NPM.DepPath.exists?("my-pkg", nm)
    end

    @tag :tmp_dir
    test "false when missing", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(nm)
      refute NPM.DepPath.exists?("missing", nm)
    end
  end

  describe "list_installed" do
    @tag :tmp_dir
    test "lists unscoped packages", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join(nm, "lodash"))
      File.mkdir_p!(Path.join(nm, "express"))
      installed = NPM.DepPath.list_installed(nm)
      assert "express" in installed
      assert "lodash" in installed
    end

    @tag :tmp_dir
    test "lists scoped packages", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join([nm, "@babel", "core"]))
      installed = NPM.DepPath.list_installed(nm)
      assert "@babel/core" in installed
    end

    @tag :tmp_dir
    test "excludes hidden dirs", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join(nm, ".bin"))
      File.mkdir_p!(Path.join(nm, "pkg"))
      installed = NPM.DepPath.list_installed(nm)
      refute ".bin" in installed
    end

    test "empty for missing dir" do
      assert [] =
               NPM.DepPath.list_installed(
                 "/tmp/nonexistent_nm_#{System.unique_integer([:positive])}"
               )
    end
  end
end
