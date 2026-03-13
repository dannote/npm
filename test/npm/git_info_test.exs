defmodule NPM.GitInfoTest do
  use ExUnit.Case, async: true

  @github_pkg %{
    "repository" => %{"type" => "git", "url" => "git+https://github.com/lodash/lodash.git"},
    "bugs" => %{"url" => "https://github.com/lodash/lodash/issues"},
    "homepage" => "https://lodash.com/"
  }

  @shorthand_pkg %{"repository" => "github:facebook/react"}

  describe "repo_url" do
    test "extracts and cleans object URL" do
      assert "https://github.com/lodash/lodash" = NPM.GitInfo.repo_url(@github_pkg)
    end

    test "resolves github shorthand" do
      assert "https://github.com/facebook/react" = NPM.GitInfo.repo_url(@shorthand_pkg)
    end

    test "resolves bare user/repo" do
      data = %{"repository" => "user/repo"}
      assert "https://github.com/user/repo" = NPM.GitInfo.repo_url(data)
    end

    test "nil for missing repository" do
      assert nil == NPM.GitInfo.repo_url(%{})
    end

    test "handles ssh URL" do
      data = %{"repository" => %{"url" => "ssh://git@github.com/user/repo.git"}}
      assert "https://github.com/user/repo" = NPM.GitInfo.repo_url(data)
    end
  end

  describe "issues_url" do
    test "returns bugs URL" do
      assert "https://github.com/lodash/lodash/issues" = NPM.GitInfo.issues_url(@github_pkg)
    end

    test "derives from repo when no bugs" do
      data = %{"repository" => %{"url" => "https://github.com/user/repo.git"}}
      assert "https://github.com/user/repo/issues" = NPM.GitInfo.issues_url(data)
    end

    test "nil for no repo" do
      assert nil == NPM.GitInfo.issues_url(%{})
    end
  end

  describe "homepage" do
    test "returns homepage field" do
      assert "https://lodash.com/" = NPM.GitInfo.homepage(@github_pkg)
    end

    test "falls back to github URL" do
      data = %{"repository" => "user/repo"}
      assert "https://github.com/user/repo" = NPM.GitInfo.homepage(data)
    end
  end

  describe "compare_url" do
    test "generates version comparison URL" do
      url = NPM.GitInfo.compare_url(@github_pkg, "4.17.20", "4.17.21")
      assert url == "https://github.com/lodash/lodash/compare/v4.17.20...v4.17.21"
    end

    test "nil for non-github package" do
      assert nil == NPM.GitInfo.compare_url(%{}, "1.0", "2.0")
    end
  end

  describe "github_repo" do
    test "extracts user/repo" do
      assert "lodash/lodash" = NPM.GitInfo.github_repo(@github_pkg)
    end

    test "nil for non-github" do
      data = %{"repository" => %{"url" => "https://gitlab.com/user/repo"}}
      assert nil == NPM.GitInfo.github_repo(data)
    end
  end

  describe "github?" do
    test "true for github repo" do
      assert NPM.GitInfo.github?(@github_pkg)
    end

    test "false for non-github" do
      refute NPM.GitInfo.github?(%{})
    end

    test "true for shorthand" do
      assert NPM.GitInfo.github?(@shorthand_pkg)
    end
  end
end
