defmodule NPM.PackageUpdate do
  @moduledoc """
  Computes available package updates by comparing locked vs latest versions.
  """

  @doc """
  Classifies an update type.
  """
  @spec update_type(String.t(), String.t()) :: atom()
  def update_type(current, latest) do
    case {parse_parts(current), parse_parts(latest)} do
      {{cm, _, _}, {lm, _, _}} when cm < lm -> :major
      {{_, cmin, _}, {_, lmin, _}} when cmin < lmin -> :minor
      {{_, _, cp}, {_, _, lp}} when cp < lp -> :patch
      _ -> :current
    end
  end

  @doc """
  Computes all available updates.
  """
  @spec compute([{String.t(), String.t(), String.t()}]) :: [map()]
  def compute(packages) do
    packages
    |> Enum.map(fn {name, current, latest} ->
      %{name: name, current: current, latest: latest, type: update_type(current, latest)}
    end)
    |> Enum.reject(&(&1.type == :current))
    |> Enum.sort_by(fn u -> {type_order(u.type), u.name} end)
  end

  @doc """
  Groups updates by type.
  """
  @spec group_by_type([map()]) :: map()
  def group_by_type(updates) do
    Enum.group_by(updates, & &1.type)
  end

  @doc """
  Counts updates by type.
  """
  @spec summary([map()]) :: map()
  def summary(updates) do
    grouped = group_by_type(updates)

    %{
      total: length(updates),
      major: length(Map.get(grouped, :major, [])),
      minor: length(Map.get(grouped, :minor, [])),
      patch: length(Map.get(grouped, :patch, []))
    }
  end

  @doc """
  Formats updates for display.
  """
  @spec format([map()]) :: String.t()
  def format([]), do: "All packages are up to date."

  def format(updates) do
    Enum.map_join(updates, "\n", fn u ->
      "#{u.name}: #{u.current} → #{u.latest} (#{u.type})"
    end)
  end

  defp parse_parts(version) do
    parts = version |> String.split(".") |> Enum.map(&safe_to_integer/1)

    case parts do
      [major, minor, patch | _] -> {major, minor, patch}
      [major, minor] -> {major, minor, 0}
      [major] -> {major, 0, 0}
      _ -> {0, 0, 0}
    end
  end

  defp safe_to_integer(str) do
    case Integer.parse(str) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp type_order(:major), do: 0
  defp type_order(:minor), do: 1
  defp type_order(:patch), do: 2
  defp type_order(_), do: 3
end
