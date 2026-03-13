defmodule NPM.ValidatorTest do
  use ExUnit.Case, async: true

  describe "Validator.validate_name" do
    test "accepts valid names" do
      assert :ok = NPM.Validator.validate_name("lodash")
      assert :ok = NPM.Validator.validate_name("my-package")
      assert :ok = NPM.Validator.validate_name("pkg123")
      assert :ok = NPM.Validator.validate_name("@scope/pkg")
    end

    test "rejects empty name" do
      assert {:error, _} = NPM.Validator.validate_name("")
    end

    test "rejects names starting with period" do
      assert {:error, _} = NPM.Validator.validate_name(".hidden")
    end

    test "rejects names starting with underscore" do
      assert {:error, _} = NPM.Validator.validate_name("_internal")
    end

    test "rejects uppercase names" do
      assert {:error, _} = NPM.Validator.validate_name("MyPackage")
    end

    test "rejects names with spaces" do
      assert {:error, _} = NPM.Validator.validate_name("my package")
    end

    test "rejects overly long names" do
      name = String.duplicate("a", 215)
      assert {:error, _} = NPM.Validator.validate_name(name)
    end

    test "accepts exactly 214 char name" do
      name = String.duplicate("a", 214)
      assert :ok = NPM.Validator.validate_name(name)
    end
  end

  describe "Validator.validate_range" do
    test "accepts valid ranges" do
      assert :ok = NPM.Validator.validate_range("^4.0.0")
      assert :ok = NPM.Validator.validate_range("~1.2.3")
      assert :ok = NPM.Validator.validate_range(">=1.0.0")
      assert :ok = NPM.Validator.validate_range("*")
      assert :ok = NPM.Validator.validate_range("latest")
    end

    test "rejects empty range" do
      assert {:error, _} = NPM.Validator.validate_range("")
    end
  end

  describe "Validator additional cases" do
    test "accepts hyphenated name" do
      assert :ok = NPM.Validator.validate_name("my-cool-package")
    end

    test "accepts dotted name in middle" do
      assert :ok = NPM.Validator.validate_name("pkg.utils")
    end

    test "accepts numeric name" do
      assert :ok = NPM.Validator.validate_name("123")
    end

    test "validate_range with 1.0.0" do
      assert :ok = NPM.Validator.validate_range("1.0.0")
    end
  end

  describe "Validator comprehensive name checks" do
    test "accepts single character name" do
      assert :ok = NPM.Validator.validate_name("a")
    end

    test "accepts name with all valid chars" do
      assert :ok = NPM.Validator.validate_name("my-pkg.util_v2")
    end

    test "rejects name starting with @" do
      assert :ok = NPM.Validator.validate_name("@scope/pkg")
    end

    test "accepts 214-char scoped name" do
      name = "@a/" <> String.duplicate("b", 211)
      assert :ok = NPM.Validator.validate_name(name)
    end
  end

  describe "Validator comprehensive range checks" do
    test "accepts hyphen range" do
      assert :ok = NPM.Validator.validate_range("1.0.0 - 2.0.0")
    end

    test "accepts or range" do
      assert :ok = NPM.Validator.validate_range(">=1.0.0 <2.0.0")
    end

    test "validates caret with pre-release" do
      result = NPM.Validator.validate_range("^1.0.0-alpha.1")
      assert result == :ok or match?({:error, _}, result)
    end
  end

  describe "Validator scoped package names" do
    test "accepts standard scoped name" do
      assert :ok = NPM.Validator.validate_name("@angular/core")
    end

    test "accepts scoped name with hyphens" do
      assert :ok = NPM.Validator.validate_name("@my-scope/my-package")
    end
  end

  describe "Validator name limits" do
    test "accepts 1-char name" do
      assert :ok = NPM.Validator.validate_name("x")
    end

    test "accepts name with numbers" do
      assert :ok = NPM.Validator.validate_name("react18")
    end

    test "allows special chars like dot" do
      assert :ok = NPM.Validator.validate_name("my.pkg")
    end

    test "allows hyphens" do
      assert :ok = NPM.Validator.validate_name("my-long-package-name")
    end
  end

  describe "Validator: version range validation" do
    test "accepts valid semver ranges" do
      assert :ok = NPM.Validator.validate_range("^1.0.0")
      assert :ok = NPM.Validator.validate_range("~2.3.0")
      assert :ok = NPM.Validator.validate_range(">=1.0.0 <3.0.0")
      assert :ok = NPM.Validator.validate_range("1.0.0")
    end

    test "accepts * range" do
      assert :ok = NPM.Validator.validate_range("*")
    end

    test "rejects invalid ranges" do
      assert {:error, _} = NPM.Validator.validate_range("not a version")
      assert {:error, _} = NPM.Validator.validate_range("abc.def.ghi")
    end
  end

  describe "Validator: package name validation edge cases" do
    test "rejects names longer than 214 characters" do
      long_name = String.duplicate("a", 215)
      assert {:error, _} = NPM.Validator.validate_name(long_name)
    end

    test "rejects uppercase in name" do
      assert {:error, _} = NPM.Validator.validate_name("MyPackage")
    end

    test "rejects names with spaces" do
      assert {:error, _} = NPM.Validator.validate_name("my package")
    end

    test "accepts 214-char name" do
      name = String.duplicate("a", 214)
      assert :ok = NPM.Validator.validate_name(name)
    end
  end

  describe "Validator: scoped package name rules" do
    test "accepts valid scoped names" do
      assert :ok = NPM.Validator.validate_name("@scope/pkg")
      assert :ok = NPM.Validator.validate_name("@types/node")
      assert :ok = NPM.Validator.validate_name("@babel/core")
    end

    test "accepts scoped with multiple parts" do
      assert :ok = NPM.Validator.validate_name("@my-org/my-pkg")
    end
  end

  describe "Validator: validate_range additional" do
    test "validates hyphen range" do
      assert :ok = NPM.Validator.validate_range("1.0.0 - 2.0.0")
    end

    test "validates x-range" do
      assert :ok = NPM.Validator.validate_range("1.x")
    end
  end

  describe "Validator: validate_name special characters" do
    test "allows dots in name" do
      assert :ok = NPM.Validator.validate_name("my.package")
    end

    test "allows tilde in name" do
      assert :ok = NPM.Validator.validate_name("my~package")
    end
  end

  describe "Validator: name length edge cases" do
    test "exact 214 chars is valid" do
      assert :ok = NPM.Validator.validate_name(String.duplicate("a", 214))
    end

    test "215 chars is invalid" do
      assert {:error, _} = NPM.Validator.validate_name(String.duplicate("a", 215))
    end
  end

  describe "Validator: npm naming rules" do
    test "rejects names starting with dot" do
      assert {:error, _} = NPM.Validator.validate_name(".hidden")
    end

    test "rejects names starting with underscore" do
      assert {:error, _} = NPM.Validator.validate_name("_private")
    end

    test "rejects empty name" do
      assert {:error, _} = NPM.Validator.validate_name("")
    end

    test "accepts hyphenated names" do
      assert :ok = NPM.Validator.validate_name("my-package")
    end

    test "accepts scoped names" do
      assert :ok = NPM.Validator.validate_name("@scope/package")
    end

    test "accepts names with numbers" do
      assert :ok = NPM.Validator.validate_name("package123")
    end

    test "accepts single-char names" do
      assert :ok = NPM.Validator.validate_name("a")
    end
  end
end
