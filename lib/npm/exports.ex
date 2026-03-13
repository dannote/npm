defmodule NPM.Exports do
  @moduledoc """
  Parse and resolve the `exports` field from `package.json`.

  Modern npm packages use the `exports` field (a.k.a. "export map") to
  define entry points and restrict access to internal modules.

  Supports:
  - String shorthand: `"exports": "./index.js"`
  - Subpath exports: `"exports": { ".": "./index.js", "./utils": "./lib/utils.js" }`
  - Conditional exports: `"exports": { "import": "./esm.js", "require": "./cjs.js" }`
  - Nested conditions: `"exports": { ".": { "import": "./esm.js", "default": "./cjs.js" } }`
  """

  @type export_map :: String.t() | %{String.t() => export_map()} | nil

  @doc """
  Parse the exports field from a package.json map.

  Returns a normalized map of subpath → target mappings, or nil if no exports field.
  """
  @spec parse(map()) :: %{String.t() => String.t() | map()} | nil
  def parse(%{"exports" => exports}) when is_binary(exports) do
    %{"." => exports}
  end

  def parse(%{"exports" => exports}) when is_map(exports) do
    if subpath_exports?(exports) do
      exports
    else
      %{"." => exports}
    end
  end

  def parse(_), do: nil

  @doc """
  Resolve an import path against an export map.

  Given a subpath (e.g. `"."`, `"./utils"`) and a list of conditions
  (e.g. `["import", "default"]`), returns the resolved file path.
  """
  @spec resolve(map(), String.t(), [String.t()]) :: {:ok, String.t()} | :error
  def resolve(export_map, subpath, conditions \\ ["default"]) do
    case Map.get(export_map, subpath) do
      nil -> :error
      target when is_binary(target) -> {:ok, target}
      target when is_map(target) -> resolve_conditions(target, conditions)
    end
  end

  @doc """
  List all exported subpaths from an export map.
  """
  @spec subpaths(map()) :: [String.t()]
  def subpaths(export_map) when is_map(export_map) do
    Map.keys(export_map) |> Enum.sort()
  end

  def subpaths(_), do: []

  @doc """
  Detect whether a package uses ESM (`type: "module"`) or CJS.
  """
  @spec module_type(map()) :: :esm | :cjs
  def module_type(%{"type" => "module"}), do: :esm
  def module_type(_), do: :cjs

  defp subpath_exports?(map) do
    Map.keys(map) |> Enum.any?(&String.starts_with?(&1, "."))
  end

  defp resolve_conditions(target, conditions) do
    Enum.find_value(conditions, :error, fn condition ->
      case Map.get(target, condition) do
        nil -> nil
        path when is_binary(path) -> {:ok, path}
        nested when is_map(nested) -> resolve_conditions(nested, conditions)
      end
    end)
  end
end
