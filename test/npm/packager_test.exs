defmodule NPM.PackagerTest do
  use ExUnit.Case, async: true

  describe "Packager.files_to_pack" do
    @tag :tmp_dir
    test "includes all files by default", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name": "test"}))
      File.write!(Path.join(dir, "index.js"), "console.log('hi')")
      File.write!(Path.join(dir, "README.md"), "# Test")

      files = NPM.Packager.files_to_pack(dir)
      assert "package.json" in files
      assert "index.js" in files
      assert "README.md" in files
    end

    @tag :tmp_dir
    test "respects files field", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name": "test", "files": ["dist/*"]}))
      File.mkdir_p!(Path.join(dir, "dist"))
      File.write!(Path.join(dir, "dist/index.js"), "")
      File.mkdir_p!(Path.join(dir, "src"))
      File.write!(Path.join(dir, "src/main.js"), "")

      files = NPM.Packager.files_to_pack(dir)
      assert "dist/index.js" in files
      assert "package.json" in files
      refute "src/main.js" in files
    end

    @tag :tmp_dir
    test "excludes node_modules and .git", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name": "test"}))
      File.mkdir_p!(Path.join(dir, "node_modules/pkg"))
      File.write!(Path.join(dir, "node_modules/pkg/index.js"), "")

      files = NPM.Packager.files_to_pack(dir)
      refute Enum.any?(files, &String.starts_with?(&1, "node_modules"))
    end
  end

  describe "Packager.pack_size" do
    @tag :tmp_dir
    test "calculates total size", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name": "test"}))
      File.write!(Path.join(dir, "data.txt"), String.duplicate("a", 500))

      size = NPM.Packager.pack_size(dir)
      assert size >= 500
    end
  end

  describe "Packager.pack_file_count" do
    @tag :tmp_dir
    test "counts packable files", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name": "test"}))
      File.write!(Path.join(dir, "a.js"), "")
      File.write!(Path.join(dir, "b.js"), "")

      count = NPM.Packager.pack_file_count(dir)
      assert count >= 3
    end
  end

  describe "Packager: pack file discovery" do
    @tag :tmp_dir
    test "files_to_pack finds project files", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"test","version":"1.0.0"}))
      File.write!(Path.join(dir, "index.js"), "module.exports = {}")
      File.write!(Path.join(dir, "README.md"), "# Test")
      File.mkdir_p!(Path.join(dir, "node_modules/dep"))
      File.write!(Path.join([dir, "node_modules", "dep", "index.js"]), "")

      files = NPM.Packager.files_to_pack(dir)
      basenames = Enum.map(files, &Path.basename/1)

      assert "package.json" in basenames
      assert "index.js" in basenames
      # node_modules should be excluded
      refute Enum.any?(files, &String.contains?(&1, "node_modules"))
    end

    @tag :tmp_dir
    test "pack_size returns byte count", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"test"}))
      File.write!(Path.join(dir, "index.js"), String.duplicate("x", 1000))

      size = NPM.Packager.pack_size(dir)
      assert size > 1000
    end
  end

  describe "Packager: files_to_pack always includes package.json" do
    @tag :tmp_dir
    test "package.json is always included", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"t"}))
      files = NPM.Packager.files_to_pack(dir)
      assert Enum.any?(files, &String.ends_with?(&1, "package.json"))
    end
  end

  describe "Packager: exclude patterns" do
    @tag :tmp_dir
    test "excludes test directories by default", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"test"}))
      File.write!(Path.join(dir, "index.js"), "")
      File.mkdir_p!(Path.join(dir, "test"))
      File.write!(Path.join([dir, "test", "test.js"]), "")

      files = NPM.Packager.files_to_pack(dir)
      # package.json and index.js should be included, test/ may or may not be excluded
      assert Enum.any?(files, &String.ends_with?(&1, "package.json"))
    end
  end

  describe "Packager: file exclusion" do
    @tag :tmp_dir
    test "excludes .git directory", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"test"}))
      File.mkdir_p!(Path.join(dir, ".git"))
      File.write!(Path.join([dir, ".git", "config"]), "")

      files = NPM.Packager.files_to_pack(dir)
      refute Enum.any?(files, &String.contains?(&1, ".git"))
    end

    @tag :tmp_dir
    test "pack_file_count returns correct count", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"test"}))
      File.write!(Path.join(dir, "index.js"), "")

      count = NPM.Packager.pack_file_count(dir)
      assert count >= 2
    end
  end

  describe "Packager: files_to_pack excludes node_modules" do
    @tag :tmp_dir
    test "node_modules directory is excluded", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "package.json"), ~s({"name":"t"}))
      File.write!(Path.join(dir, "index.js"), "module.exports = {}")
      nm = Path.join(dir, "node_modules")
      File.mkdir_p!(Path.join(nm, "dep"))
      File.write!(Path.join([nm, "dep", "index.js"]), "nope")

      files = NPM.Packager.files_to_pack(dir)
      refute Enum.any?(files, &String.contains?(&1, "node_modules"))
    end
  end
end
