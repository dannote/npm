defmodule NPM.ProgressReporterTest do
  use ExUnit.Case, async: true

  describe "resolving" do
    test "shows progress" do
      msg = NPM.ProgressReporter.resolving(5, 10)
      assert msg =~ "5/10"
      assert msg =~ "50%"
    end

    test "handles zero total" do
      msg = NPM.ProgressReporter.resolving(0, 0)
      assert msg =~ "0%"
    end
  end

  describe "fetching" do
    test "shows package name and progress" do
      msg = NPM.ProgressReporter.fetching("lodash", 3, 10)
      assert msg =~ "lodash"
      assert msg =~ "3/10"
    end
  end

  describe "linking" do
    test "shows link progress" do
      msg = NPM.ProgressReporter.linking(7, 10)
      assert msg =~ "7/10"
    end
  end

  describe "done" do
    test "resolve step" do
      assert "✓ Resolved in 150ms" = NPM.ProgressReporter.done(:resolve, 150)
    end

    test "install step with seconds" do
      assert "✓ Installed in 2.5s" = NPM.ProgressReporter.done(:install, 2500)
    end

    test "custom step" do
      assert "✓ audit in 50ms" = NPM.ProgressReporter.done(:audit, 50)
    end
  end

  describe "breakdown" do
    test "formats steps" do
      steps = [resolve: 100, fetch: 500, link: 200]
      output = NPM.ProgressReporter.breakdown(steps)
      assert output =~ "resolve: 100ms"
      assert output =~ "fetch: 500ms"
      assert output =~ "link: 200ms"
    end
  end

  describe "format_time" do
    test "milliseconds" do
      assert "500ms" = NPM.ProgressReporter.format_time(500)
    end

    test "seconds" do
      assert "1.5s" = NPM.ProgressReporter.format_time(1500)
    end
  end
end
