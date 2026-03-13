defmodule NPM.DeprecationTest do
  use ExUnit.Case, async: true

  describe "check against metadata" do
    test "finds deprecated packages" do
      lockfile = %{
        "request" => %{version: "2.88.2", integrity: "", tarball: "", dependencies: %{}},
        "lodash" => %{version: "4.17.21", integrity: "", tarball: "", dependencies: %{}}
      }

      metadata = %{
        "request" => %{deprecated: "Use got or node-fetch instead"},
        "lodash" => %{deprecated: nil}
      }

      entries = NPM.Deprecation.check(lockfile, metadata)
      assert length(entries) == 1
      assert hd(entries).package == "request"
      assert hd(entries).message =~ "got"
    end

    test "no deprecated packages" do
      lockfile = %{
        "react" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}}
      }

      metadata = %{"react" => %{deprecated: nil}}
      assert [] = NPM.Deprecation.check(lockfile, metadata)
    end

    test "missing metadata returns no entries" do
      lockfile = %{
        "pkg" => %{version: "1.0.0", integrity: "", tarball: "", dependencies: %{}}
      }

      assert [] = NPM.Deprecation.check(lockfile, %{})
    end
  end

  describe "extract from package.json" do
    test "returns message when deprecated" do
      assert "Use X instead" = NPM.Deprecation.extract(%{"deprecated" => "Use X instead"})
    end

    test "returns nil when not deprecated" do
      assert nil == NPM.Deprecation.extract(%{"name" => "pkg"})
    end

    test "returns nil for empty string" do
      assert nil == NPM.Deprecation.extract(%{"deprecated" => ""})
    end

    test "returns nil for non-string deprecated" do
      assert nil == NPM.Deprecation.extract(%{"deprecated" => true})
    end
  end

  describe "deprecated?" do
    test "true for deprecated package" do
      assert NPM.Deprecation.deprecated?(%{"deprecated" => "old"})
    end

    test "false for non-deprecated" do
      refute NPM.Deprecation.deprecated?(%{"name" => "pkg"})
    end

    test "false for empty deprecation string" do
      refute NPM.Deprecation.deprecated?(%{"deprecated" => ""})
    end
  end

  describe "format_warning" do
    test "includes package, version, and message" do
      entry = %{package: "request", version: "2.88.2", message: "Use got instead"}
      warning = NPM.Deprecation.format_warning(entry)
      assert warning =~ "DEPRECATED"
      assert warning =~ "request@2.88.2"
      assert warning =~ "Use got instead"
    end
  end

  describe "scan node_modules" do
    @tag :tmp_dir
    test "finds deprecated packages", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "old-pkg")
      File.mkdir_p!(pkg)

      File.write!(
        Path.join(pkg, "package.json"),
        ~s({"name":"old-pkg","version":"1.0.0","deprecated":"Use new-pkg instead"})
      )

      entries = NPM.Deprecation.scan(nm)
      assert length(entries) == 1
      assert hd(entries).package == "old-pkg"
    end

    @tag :tmp_dir
    test "skips non-deprecated packages", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join(nm, "good-pkg")
      File.mkdir_p!(pkg)

      File.write!(
        Path.join(pkg, "package.json"),
        ~s({"name":"good-pkg","version":"2.0.0"})
      )

      assert [] = NPM.Deprecation.scan(nm)
    end

    @tag :tmp_dir
    test "handles scoped deprecated packages", %{tmp_dir: dir} do
      nm = Path.join(dir, "node_modules")
      pkg = Path.join([nm, "@old", "lib"])
      File.mkdir_p!(pkg)

      File.write!(
        Path.join(pkg, "package.json"),
        ~s({"name":"@old/lib","version":"0.5.0","deprecated":"Unmaintained"})
      )

      entries = NPM.Deprecation.scan(nm)
      assert length(entries) == 1
      assert hd(entries).package == "@old/lib"
    end

    test "nonexistent directory" do
      assert [] = NPM.Deprecation.scan("/tmp/nonexistent_#{System.unique_integer([:positive])}")
    end
  end
end
