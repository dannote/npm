defmodule NPM.NPMTest do
  @moduledoc false
  use ExUnit.Case, async: true

  describe "NPM.install with empty deps" do
    @tag :tmp_dir
    test "reports no dependencies found", %{tmp_dir: dir} do
      path = Path.join(dir, "package.json")
      File.write!(path, ~s({"name":"empty-project"}))

      result = NPM.install(path: path)
      assert result == :ok or match?({:ok, _}, result)
    end
  end

  describe "NPM.list with no lockfile" do
    @tag :tmp_dir
    test "returns empty list", %{tmp_dir: dir} do
      old = File.cwd!()
      File.cd!(dir)

      File.write!("package.json", ~s({"name":"t"}))
      result = NPM.list()
      assert {:ok, []} = result

      File.cd!(old)
    end
  end

  describe "NPM.outdated structure" do
    test "module exists and is callable" do
      assert function_exported?(NPM, :list, 0)
      assert function_exported?(NPM, :install, 0)
      assert function_exported?(NPM, :install, 1)
      assert function_exported?(NPM, :add, 1)
      assert function_exported?(NPM, :add, 2)
      assert function_exported?(NPM, :add, 3)
      assert function_exported?(NPM, :remove, 1)
      assert function_exported?(NPM, :update, 0)
      assert function_exported?(NPM, :update, 1)
      assert function_exported?(NPM, :get, 0)
    end
  end
end
