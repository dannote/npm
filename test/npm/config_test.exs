defmodule NPM.ConfigTest do
  use ExUnit.Case, async: true

  describe "Config.parse_npmrc" do
    test "parses key=value pairs" do
      content = "registry=https://registry.example.com\nalways-auth=true"
      result = NPM.Config.parse_npmrc(content)
      assert result["registry"] == "https://registry.example.com"
      assert result["always-auth"] == "true"
    end

    test "ignores comments" do
      content = "# this is a comment\nregistry=https://example.com\n# another comment"
      result = NPM.Config.parse_npmrc(content)
      assert map_size(result) == 1
      assert result["registry"] == "https://example.com"
    end

    test "ignores blank lines" do
      content = "\nregistry=https://example.com\n\n\n"
      result = NPM.Config.parse_npmrc(content)
      assert map_size(result) == 1
    end

    test "handles auth tokens with = in value" do
      content = "//registry.npmjs.org/:_authToken=abc123def456=="
      result = NPM.Config.parse_npmrc(content)
      assert result["//registry.npmjs.org/:_authToken"] == "abc123def456=="
    end

    test "handles empty content" do
      assert NPM.Config.parse_npmrc("") == %{}
    end

    test "handles whitespace around values" do
      content = "  registry = https://example.com  "
      result = NPM.Config.parse_npmrc(content)
      assert result["registry"] == "https://example.com"
    end
  end

  describe "Config registry priority" do
    test "env var overrides everything" do
      original = System.get_env("NPM_REGISTRY")
      System.put_env("NPM_REGISTRY", "https://custom.registry.io")

      assert NPM.Config.registry() == "https://custom.registry.io"

      if original,
        do: System.put_env("NPM_REGISTRY", original),
        else: System.delete_env("NPM_REGISTRY")
    end

    test "defaults to npmjs.org" do
      original = System.get_env("NPM_REGISTRY")
      System.delete_env("NPM_REGISTRY")

      result = NPM.Config.registry()
      assert result =~ "registry.npmjs.org" or result =~ "npm"

      if original, do: System.put_env("NPM_REGISTRY", original)
    end
  end

  describe "Config.parse_npmrc edge cases" do
    test "handles multiple = signs in value" do
      result = NPM.Config.parse_npmrc("key=value=with=equals")
      assert result["key"] == "value=with=equals"
    end

    test "handles lines with only comments" do
      result = NPM.Config.parse_npmrc("# comment\n# another")
      assert result == %{}
    end

    test "handles mixed content" do
      content = """
      # npm config
      registry=https://example.com
      # auth stuff
      always-auth=true
      save-exact=true
      """

      result = NPM.Config.parse_npmrc(content)
      assert map_size(result) == 3
      assert result["registry"] == "https://example.com"
      assert result["always-auth"] == "true"
      assert result["save-exact"] == "true"
    end
  end

  describe "Config: parse_npmrc handles env vars" do
    test "parses key=value with env var references" do
      content = "registry=${NPM_REGISTRY:-https://registry.npmjs.org/}"
      result = NPM.Config.parse_npmrc(content)
      assert Map.has_key?(result, "registry")
    end
  end

  describe "Config: multi-line npmrc" do
    test "parses complex real-world npmrc" do
      content = """
      registry=https://registry.npmjs.org/
      @myorg:registry=https://npm.myorg.com/
      //npm.myorg.com/:_authToken=npm_abcdef
      save-exact=true
      engine-strict=true
      fund=false
      audit=false
      """

      result = NPM.Config.parse_npmrc(content)
      assert map_size(result) == 7
      assert result["fund"] == "false"
      assert result["audit"] == "false"
    end
  end

  describe "Config: parse_npmrc round-trip" do
    @tag :tmp_dir
    test "manually written npmrc parses correctly", %{tmp_dir: dir} do
      path = Path.join(dir, ".npmrc")
      content = "registry=https://custom.registry.com\nsave-exact=true\n"
      File.write!(path, content)

      result = NPM.Config.parse_npmrc(File.read!(path))
      assert result["registry"] == "https://custom.registry.com"
      assert result["save-exact"] == "true"
    end
  end

  describe "Config: parse_npmrc edge cases" do
    test "handles = signs in values" do
      content = "//registry.npmjs.org/:_authToken=npm_abcdef123456=="
      result = NPM.Config.parse_npmrc(content)
      assert result["//registry.npmjs.org/:_authToken"] == "npm_abcdef123456=="
    end

    test "handles trailing whitespace" do
      content = "registry=https://registry.npmjs.org/  \n"
      result = NPM.Config.parse_npmrc(content)
      assert result["registry"] == "https://registry.npmjs.org/"
    end
  end

  describe "Config: real .npmrc patterns" do
    test "parses registry config" do
      content = "registry=https://registry.npmjs.org/"
      result = NPM.Config.parse_npmrc(content)
      assert result["registry"] == "https://registry.npmjs.org/"
    end

    test "parses scoped registry" do
      content = "@mycompany:registry=https://npm.mycompany.com"
      result = NPM.Config.parse_npmrc(content)
      assert result["@mycompany:registry"] == "https://npm.mycompany.com"
    end

    test "parses auth token" do
      content = "//registry.npmjs.org/:_authToken=npm_abc123"
      result = NPM.Config.parse_npmrc(content)
      assert result["//registry.npmjs.org/:_authToken"] == "npm_abc123"
    end

    test "ignores comments and blank lines" do
      content = """
      # This is a comment
      registry=https://registry.npmjs.org/

      # Another comment
      always-auth=false
      """

      result = NPM.Config.parse_npmrc(content)
      assert map_size(result) == 2
      assert result["registry"] == "https://registry.npmjs.org/"
    end

    test "handles real-world .npmrc with multiple settings" do
      content = """
      registry=https://registry.npmjs.org/
      @myco:registry=https://npm.myco.com/
      //npm.myco.com/:_authToken=secret123
      save-exact=true
      engine-strict=true
      """

      result = NPM.Config.parse_npmrc(content)
      assert map_size(result) == 5
      assert result["save-exact"] == "true"
    end
  end

  describe "Config: registry and auth_token" do
    test "registry returns a URL string" do
      url = NPM.Config.registry()
      assert is_binary(url)
      assert String.starts_with?(url, "https://")
    end

    test "auth_token returns nil or string" do
      token = NPM.Config.auth_token()
      assert is_nil(token) or is_binary(token)
    end
  end
end
