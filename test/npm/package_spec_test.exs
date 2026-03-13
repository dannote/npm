defmodule NPM.PackageSpecTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Npm.Install, as: NpmInstall

  describe "parse_package_spec" do
    test "plain name" do
      assert {"lodash", "latest"} = NpmInstall.parse_package_spec("lodash")
    end

    test "name with range" do
      assert {"lodash", "^4.0"} = NpmInstall.parse_package_spec("lodash@^4.0")
    end

    test "scoped package" do
      assert {"@types/node", "latest"} = NpmInstall.parse_package_spec("@types/node")
    end

    test "scoped package with range" do
      assert {"@types/node", "^20.0.0"} =
               NpmInstall.parse_package_spec("@types/node@^20.0.0")
    end

    test "scoped package with exact version" do
      assert {"@babel/core", "7.24.0"} =
               NpmInstall.parse_package_spec("@babel/core@7.24.0")
    end

    test "scoped package with tilde range" do
      assert {"@scope/pkg", "~1.2.3"} =
               NpmInstall.parse_package_spec("@scope/pkg@~1.2.3")
    end
  end

  describe "parse_package_spec with version types" do
    test "exact version" do
      assert {"lodash", "4.17.21"} = NpmInstall.parse_package_spec("lodash@4.17.21")
    end

    test "caret range" do
      assert {"lodash", "^4.17"} = NpmInstall.parse_package_spec("lodash@^4.17")
    end

    test "tilde range" do
      assert {"lodash", "~4.17.0"} = NpmInstall.parse_package_spec("lodash@~4.17.0")
    end

    test "x-range" do
      assert {"lodash", "4.x"} = NpmInstall.parse_package_spec("lodash@4.x")
    end

    test "star range" do
      assert {"lodash", "*"} = NpmInstall.parse_package_spec("lodash@*")
    end

    test "greater-than range" do
      assert {"lodash", ">=4.0.0"} = NpmInstall.parse_package_spec("lodash@>=4.0.0")
    end
  end

  describe "PackageSpec.parse" do
    test "plain name" do
      spec = NPM.PackageSpec.parse("lodash")
      assert spec.name == "lodash"
      assert spec.range == nil
      assert spec.type == :registry
    end

    test "name with range" do
      spec = NPM.PackageSpec.parse("lodash@^4.0")
      assert spec.name == "lodash"
      assert spec.range == "^4.0"
      assert spec.type == :registry
    end

    test "scoped package" do
      spec = NPM.PackageSpec.parse("@babel/core@7.0.0")
      assert spec.name == "@babel/core"
      assert spec.range == "7.0.0"
      assert spec.type == :registry
    end

    test "scoped without range" do
      spec = NPM.PackageSpec.parse("@scope/pkg")
      assert spec.name == "@scope/pkg"
      assert spec.range == nil
      assert spec.type == :registry
    end

    test "alias" do
      spec = NPM.PackageSpec.parse("npm:react@^18.0")
      assert spec.name == "react"
      assert spec.range == "^18.0"
      assert spec.type == :alias
    end

    test "file reference" do
      spec = NPM.PackageSpec.parse("file:../local")
      assert spec.type == :file
    end

    test "git reference" do
      spec = NPM.PackageSpec.parse("git+https://github.com/user/repo")
      assert spec.type == :git
    end

    test "github shorthand" do
      spec = NPM.PackageSpec.parse("github:user/repo")
      assert spec.type == :git
    end

    test "http URL" do
      spec = NPM.PackageSpec.parse("https://example.com/pkg.tgz")
      assert spec.type == :url
    end
  end

  describe "PackageSpec.registry?" do
    test "registry spec" do
      spec = NPM.PackageSpec.parse("lodash@^4.0")
      assert NPM.PackageSpec.registry?(spec)
    end

    test "non-registry spec" do
      spec = NPM.PackageSpec.parse("file:../local")
      refute NPM.PackageSpec.registry?(spec)
    end
  end

  describe "PackageSpec.to_string" do
    test "with range" do
      spec = NPM.PackageSpec.parse("lodash@^4.0")
      assert NPM.PackageSpec.to_string(spec) == "lodash@^4.0"
    end

    test "without range" do
      spec = NPM.PackageSpec.parse("lodash")
      assert NPM.PackageSpec.to_string(spec) == "lodash"
    end
  end

  describe "PackageSpec: edge case patterns" do
    test "version with prerelease" do
      spec = NPM.PackageSpec.parse("pkg@1.0.0-beta.1")
      assert spec.name == "pkg"
      assert spec.range == "1.0.0-beta.1"
    end

    test "scoped package without version" do
      spec = NPM.PackageSpec.parse("@scope/pkg")
      assert spec.name == "@scope/pkg"
      assert spec.type == :registry
    end

    test "url spec" do
      spec = NPM.PackageSpec.parse("https://github.com/user/repo/archive/main.tar.gz")
      assert spec.type == :url
    end
  end

  describe "PackageSpec: tag and latest patterns" do
    test "bare name with @latest" do
      spec = NPM.PackageSpec.parse("lodash@latest")
      assert spec.name == "lodash"
      assert spec.range == "latest"
    end

    test "bare name defaults to registry type" do
      spec = NPM.PackageSpec.parse("express")
      assert spec.type == :registry
    end
  end

  describe "PackageSpec: git spec patterns" do
    test "git+https URL" do
      spec = NPM.PackageSpec.parse("git+https://github.com/user/repo.git")
      assert spec.type == :git
    end

    test "git+ssh URL" do
      spec = NPM.PackageSpec.parse("git+ssh://git@github.com:user/repo.git")
      assert spec.type == :git
    end
  end

  describe "PackageSpec: real specifier patterns from npm" do
    test "npm install react" do
      spec = NPM.PackageSpec.parse("react")
      assert spec.name == "react"
      assert spec.type == :registry
      assert spec.range == nil
    end

    test "npm install react@^18.0.0" do
      spec = NPM.PackageSpec.parse("react@^18.0.0")
      assert spec.name == "react"
      assert spec.range == "^18.0.0"
    end

    test "npm install @babel/core@7.0.0" do
      spec = NPM.PackageSpec.parse("@babel/core@7.0.0")
      assert spec.name == "@babel/core"
      assert spec.range == "7.0.0"
    end

    test "npm install file:../local-pkg" do
      spec = NPM.PackageSpec.parse("file:../local-pkg")
      assert spec.type == :file
    end

    test "npm install github:user/repo" do
      spec = NPM.PackageSpec.parse("github:user/repo")
      assert spec.type == :git
    end
  end

  describe "PackageSpec: parse URL spec" do
    test "https tarball URL" do
      spec = NPM.PackageSpec.parse("https://registry.npmjs.org/react/-/react-18.2.0.tgz")
      assert spec.type == :url
    end
  end

  describe "PackageSpec: parse file spec" do
    test "file: prefix" do
      spec = NPM.PackageSpec.parse("file:./local-pkg")
      assert spec.type == :file
    end
  end
end
