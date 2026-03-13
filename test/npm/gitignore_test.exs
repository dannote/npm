defmodule NPM.GitignoreTest do
  use ExUnit.Case, async: true

  describe "essential" do
    test "includes node_modules" do
      assert "node_modules/" in NPM.Gitignore.essential()
    end
  end

  describe "recommended" do
    test "includes more patterns" do
      rec = NPM.Gitignore.recommended()
      assert "node_modules/" in rec
      assert ".env" in rec
    end
  end

  describe "covers_node_modules?" do
    test "true with node_modules/" do
      assert NPM.Gitignore.covers_node_modules?("node_modules/\n.env\n")
    end

    test "true with node_modules (no slash)" do
      assert NPM.Gitignore.covers_node_modules?("node_modules\n")
    end

    test "false when missing" do
      refute NPM.Gitignore.covers_node_modules?(".env\ndist/\n")
    end
  end

  describe "missing" do
    test "reports missing patterns" do
      content = ".env\ndist/"
      missing = NPM.Gitignore.missing(content)
      assert "node_modules/" in missing
    end

    test "empty when all present" do
      content = "node_modules/\n.npm/"
      assert [] = NPM.Gitignore.missing(content)
    end

    test "handles bare pattern without slash" do
      content = "node_modules\n.npm"
      assert [] = NPM.Gitignore.missing(content)
    end
  end

  describe "generate" do
    test "generates recommended by default" do
      content = NPM.Gitignore.generate()
      assert content =~ "node_modules/"
      assert content =~ ".env"
    end

    test "generates essential only" do
      content = NPM.Gitignore.generate(recommended: false)
      assert content =~ "node_modules/"
      refute content =~ ".env"
    end

    test "includes extra patterns" do
      content = NPM.Gitignore.generate(extra: ["dist/", "build/"])
      assert content =~ "dist/"
    end
  end

  describe "check" do
    @tag :tmp_dir
    test "finds missing patterns", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".gitignore"), ".env\n")
      assert {:ok, missing} = NPM.Gitignore.check(dir)
      assert "node_modules/" in missing
    end

    @tag :tmp_dir
    test "empty when all present", %{tmp_dir: dir} do
      File.write!(Path.join(dir, ".gitignore"), "node_modules/\n.npm/\n")
      assert {:ok, []} = NPM.Gitignore.check(dir)
    end

    @tag :tmp_dir
    test "error when no .gitignore", %{tmp_dir: dir} do
      assert {:error, :not_found} = NPM.Gitignore.check(dir)
    end
  end
end
