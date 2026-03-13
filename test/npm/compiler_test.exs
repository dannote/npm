defmodule NPM.CompilerTest do
  use ExUnit.Case, async: true

  describe "compiler module" do
    test "implements Mix.Task.Compiler behaviour" do
      behaviours = NPM.Compiler.__info__(:attributes)[:behaviour] || []
      assert Mix.Task.Compiler in behaviours
    end

    test "has run/1 function" do
      funs = NPM.Compiler.__info__(:functions)
      assert {:run, 1} in funs
    end
  end
end
