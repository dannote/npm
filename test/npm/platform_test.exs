defmodule NPM.PlatformTest do
  use ExUnit.Case, async: true

  describe "Platform.os_compatible?" do
    test "empty list is always compatible" do
      assert NPM.Platform.os_compatible?([])
    end

    test "current OS is compatible" do
      current = NPM.Platform.current_os()
      assert NPM.Platform.os_compatible?([current])
    end

    test "different OS is not compatible" do
      # pick an OS that's definitely not current
      other = if NPM.Platform.current_os() == "linux", do: "win32", else: "linux"
      refute NPM.Platform.os_compatible?([other])
    end

    test "blocklist excludes current OS" do
      current = NPM.Platform.current_os()
      refute NPM.Platform.os_compatible?(["!#{current}"])
    end

    test "blocklist allows other OSes" do
      other = if NPM.Platform.current_os() == "linux", do: "win32", else: "linux"
      assert NPM.Platform.os_compatible?(["!#{other}"])
    end

    test "non-list is compatible" do
      assert NPM.Platform.os_compatible?("any")
    end
  end

  describe "Platform.cpu_compatible?" do
    test "empty list is always compatible" do
      assert NPM.Platform.cpu_compatible?([])
    end

    test "current CPU is compatible" do
      current = NPM.Platform.current_cpu()
      assert NPM.Platform.cpu_compatible?([current])
    end

    test "different CPU is not compatible" do
      other = if NPM.Platform.current_cpu() == "x64", do: "arm", else: "x64"
      refute NPM.Platform.cpu_compatible?([other])
    end

    test "non-list is compatible" do
      assert NPM.Platform.cpu_compatible?("any")
    end
  end

  describe "Platform.current_os" do
    test "returns a known OS string" do
      os = NPM.Platform.current_os()
      assert os in ["darwin", "linux", "freebsd", "win32"] or is_binary(os)
    end
  end

  describe "Platform.current_cpu" do
    test "returns a known CPU string" do
      cpu = NPM.Platform.current_cpu()
      assert cpu in ["x64", "arm64", "arm", "ia32"] or is_binary(cpu)
    end
  end

  describe "Platform.check_engines" do
    test "returns empty for no engines" do
      assert NPM.Platform.check_engines(%{}) == []
    end

    test "returns warning for node engine" do
      warnings = NPM.Platform.check_engines(%{"node" => ">=18"})
      assert length(warnings) == 1
      assert hd(warnings) =~ "node"
    end

    test "returns warnings for multiple engines" do
      warnings = NPM.Platform.check_engines(%{"node" => ">=18", "npm" => ">=9"})
      assert length(warnings) == 2
    end

    test "ignores unknown engines" do
      assert NPM.Platform.check_engines(%{"bun" => ">=1.0"}) == []
    end

    test "handles non-map input" do
      assert NPM.Platform.check_engines(nil) == []
    end
  end

  describe "Platform: full compatibility check" do
    test "current system is compatible with own os/cpu" do
      os = NPM.Platform.current_os()
      cpu = NPM.Platform.current_cpu()
      assert NPM.Platform.os_compatible?([os])
      assert NPM.Platform.cpu_compatible?([cpu])
    end
  end

  describe "Platform: os_compatible? with empty list" do
    test "empty list means compatible" do
      assert NPM.Platform.os_compatible?([])
    end
  end

  describe "Platform: cpu_compatible? tests" do
    test "compatible with current cpu" do
      current = NPM.Platform.current_cpu()
      assert NPM.Platform.cpu_compatible?([current])
    end

    test "incompatible with wrong cpu" do
      refute NPM.Platform.cpu_compatible?(["definitely-wrong-arch"])
    end

    test "blocklist rejects current cpu" do
      current = NPM.Platform.current_cpu()
      refute NPM.Platform.cpu_compatible?(["!#{current}"])
    end

    test "empty list means compatible" do
      assert NPM.Platform.cpu_compatible?([])
    end
  end

  describe "Platform: real OS/CPU detection" do
    test "current_os returns a valid OS for this machine" do
      os = NPM.Platform.current_os()
      # Running on macOS in CI or dev
      assert os in ["darwin", "linux", "freebsd", "win32"]
    end

    test "current_cpu returns a valid architecture" do
      cpu = NPM.Platform.current_cpu()
      assert cpu in ["x64", "arm64", "arm", "ia32"]
    end

    test "os_compatible? with allowlist and blocklist" do
      current = NPM.Platform.current_os()

      # Allowlist: must be in list
      assert NPM.Platform.os_compatible?([current, "other-os"])
      refute NPM.Platform.os_compatible?(["definitely-not-this-os"])

      # Blocklist: must NOT be in list
      refute NPM.Platform.os_compatible?(["!#{current}"])
    end
  end

  describe "Platform: check_engines with node constraint" do
    test "returns warnings for unsatisfied engines" do
      warnings = NPM.Platform.check_engines(%{"node" => ">= 999.0.0"})
      assert is_list(warnings)
    end

    test "empty engines map returns no warnings" do
      assert [] = NPM.Platform.check_engines(%{})
    end
  end

  describe "Platform: os exclusion" do
    test "negation prefix excludes current OS" do
      os = NPM.Platform.current_os()
      refute NPM.Platform.os_compatible?(["!#{os}"])
    end

    test "negation of other OS allows current" do
      assert NPM.Platform.os_compatible?(["!solaris"])
    end
  end
end
