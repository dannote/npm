defmodule NPM.ReportTest do
  use ExUnit.Case, async: true

  @lockfile %{
    "@babel/core" => %{version: "7.23.0", integrity: "", tarball: "", dependencies: %{}},
    "@babel/parser" => %{version: "7.23.0", integrity: "", tarball: "", dependencies: %{}},
    "lodash" => %{version: "4.17.21", integrity: "", tarball: "", dependencies: %{}},
    "react" => %{version: "18.2.0", integrity: "", tarball: "", dependencies: %{}},
    "express" => %{version: "4.18.2", integrity: "", tarball: "", dependencies: %{}}
  }

  describe "dependency_summary" do
    test "counts total and scoped packages" do
      summary = NPM.Report.dependency_summary(@lockfile)
      assert summary.total == 5
      assert summary.scoped == 2
      assert summary.unscoped == 3
    end

    test "empty lockfile" do
      summary = NPM.Report.dependency_summary(%{})
      assert summary.total == 0
      assert summary.scoped_pct == 0.0
    end
  end

  describe "version_summary" do
    test "computes major version distribution" do
      summary = NPM.Report.version_summary(@lockfile)
      assert summary.total == 5
      assert is_list(summary.major_distribution)
    end

    test "empty lockfile" do
      summary = NPM.Report.version_summary(%{})
      assert summary.total == 0
    end
  end

  describe "format_summary" do
    test "formats readable output" do
      summary = NPM.Report.dependency_summary(@lockfile)
      formatted = NPM.Report.format_summary(summary)
      assert formatted =~ "Dependencies: 5"
      assert formatted =~ "Scoped: 2"
    end
  end

  describe "full_report" do
    test "combines all report sections" do
      pkg_data = %{
        "name" => "my-app",
        "version" => "1.0.0",
        "license" => "MIT",
        "repository" => "user/repo"
      }

      report = NPM.Report.full_report(@lockfile, pkg_data)
      assert report.name == "my-app"
      assert report.dependencies.total == 5
      assert report.has_license
      assert report.has_repository
    end

    test "missing fields" do
      pkg_data = %{"name" => "bare"}
      report = NPM.Report.full_report(%{}, pkg_data)
      refute report.has_license
      refute report.has_repository
    end
  end
end
