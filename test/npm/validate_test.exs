defmodule NPM.ValidateTest do
  use ExUnit.Case, async: true

  @valid_pkg %{"name" => "my-app", "version" => "1.0.0"}

  describe "validate" do
    test "no issues for valid package" do
      assert [] = NPM.Validate.validate(@valid_pkg)
    end

    test "missing name" do
      issues = NPM.Validate.validate(%{"version" => "1.0.0"})
      assert Enum.any?(issues, &(&1.field == "name" and &1.level == :error))
    end

    test "missing version" do
      issues = NPM.Validate.validate(%{"name" => "pkg"})
      assert Enum.any?(issues, &(&1.field == "version" and &1.level == :error))
    end

    test "empty name" do
      issues = NPM.Validate.validate(%{"name" => "", "version" => "1.0.0"})
      assert Enum.any?(issues, &(&1.message =~ "empty"))
    end

    test "name starting with dot" do
      issues = NPM.Validate.validate(%{"name" => ".hidden", "version" => "1.0.0"})
      assert Enum.any?(issues, &(&1.message =~ "dot"))
    end

    test "name starting with underscore" do
      issues = NPM.Validate.validate(%{"name" => "_private", "version" => "1.0.0"})
      assert Enum.any?(issues, &(&1.message =~ "underscore"))
    end

    test "name too long" do
      long_name = String.duplicate("a", 215)
      issues = NPM.Validate.validate(%{"name" => long_name, "version" => "1.0.0"})
      assert Enum.any?(issues, &(&1.message =~ "214"))
    end

    test "uppercase name warns" do
      issues = NPM.Validate.validate(%{"name" => "MyPkg", "version" => "1.0.0"})
      assert Enum.any?(issues, &(&1.level == :warning and &1.message =~ "lowercase"))
    end

    test "scoped uppercase does not warn" do
      issues = NPM.Validate.validate(%{"name" => "@org/MyPkg", "version" => "1.0.0"})
      refute Enum.any?(issues, &(&1.message =~ "lowercase"))
    end

    test "invalid semver" do
      issues = NPM.Validate.validate(%{"name" => "pkg", "version" => "not.valid"})
      assert Enum.any?(issues, &(&1.message =~ "semver"))
    end

    test "non-string name" do
      issues = NPM.Validate.validate(%{"name" => 123, "version" => "1.0.0"})
      assert Enum.any?(issues, &(&1.message =~ "must be a string"))
    end

    test "non-string version" do
      issues = NPM.Validate.validate(%{"name" => "pkg", "version" => 1})
      assert Enum.any?(issues, &(&1.field == "version" and &1.message =~ "must be a string"))
    end

    test "non-object dependencies" do
      data = Map.put(@valid_pkg, "dependencies", "not-a-map")
      issues = NPM.Validate.validate(data)
      assert Enum.any?(issues, &(&1.field == "dependencies"))
    end

    test "non-string version in dependencies" do
      data = Map.put(@valid_pkg, "dependencies", %{"lodash" => 4})
      issues = NPM.Validate.validate(data)
      assert Enum.any?(issues, &(&1.message =~ "lodash"))
    end

    test "non-object data returns error" do
      issues = NPM.Validate.validate("not a map")
      assert Enum.any?(issues, &(&1.message =~ "object"))
    end

    test "wrong type for keywords" do
      data = Map.put(@valid_pkg, "keywords", "not-a-list")
      issues = NPM.Validate.validate(data)
      assert Enum.any?(issues, &(&1.field == "keywords"))
    end

    test "wrong type for private" do
      data = Map.put(@valid_pkg, "private", "yes")
      issues = NPM.Validate.validate(data)
      assert Enum.any?(issues, &(&1.field == "private"))
    end
  end

  describe "errors/warnings" do
    test "errors returns only errors" do
      errs = NPM.Validate.errors(%{})
      assert Enum.all?(errs, &(&1.level == :error))
    end

    test "warnings returns only warnings" do
      warns = NPM.Validate.warnings(%{"name" => "CamelCase", "version" => "1.0.0"})
      assert Enum.all?(warns, &(&1.level == :warning))
    end
  end

  describe "valid?" do
    test "true for valid package" do
      assert NPM.Validate.valid?(@valid_pkg)
    end

    test "false for missing required" do
      refute NPM.Validate.valid?(%{})
    end
  end

  describe "unknown_fields" do
    test "detects unknown fields" do
      data = Map.merge(@valid_pkg, %{"custom_field" => true, "another" => 1})
      unknown = NPM.Validate.unknown_fields(data)
      assert "another" in unknown
      assert "custom_field" in unknown
    end

    test "ignores _prefixed fields" do
      data = Map.put(@valid_pkg, "_internal", true)
      unknown = NPM.Validate.unknown_fields(data)
      refute "_internal" in unknown
    end

    test "known fields not flagged" do
      data = Map.merge(@valid_pkg, %{"description" => "hi", "license" => "MIT"})
      assert [] = NPM.Validate.unknown_fields(data)
    end
  end

  describe "format_issues" do
    test "no issues message" do
      assert "No issues found." = NPM.Validate.format_issues([])
    end

    test "formats error" do
      issues = [%{level: :error, field: "name", message: "missing"}]
      assert "ERROR [name]: missing" = NPM.Validate.format_issues(issues)
    end

    test "formats warning" do
      issues = [%{level: :warning, field: "name", message: "should be lowercase"}]
      assert "WARN [name]: should be lowercase" = NPM.Validate.format_issues(issues)
    end

    test "formats nil field" do
      issues = [%{level: :error, field: nil, message: "invalid"}]
      assert "ERROR: invalid" = NPM.Validate.format_issues(issues)
    end
  end
end
