defmodule NPM.Config do
  @moduledoc """
  Read npm configuration from `.npmrc` files.

  Checks for `.npmrc` in the project directory and home directory.
  Environment variables take precedence over file configuration.
  """

  @doc """
  Read the effective registry URL.

  Priority: `NPM_REGISTRY` env var > project `.npmrc` > home `.npmrc` > default.
  """
  @spec registry :: String.t()
  def registry do
    System.get_env("NPM_REGISTRY") ||
      read_npmrc_value("registry") ||
      "https://registry.npmjs.org"
  end

  @doc """
  Read the auth token.

  Priority: `NPM_TOKEN` env var > project `.npmrc` > home `.npmrc`.
  """
  @spec auth_token :: String.t() | nil
  def auth_token do
    System.get_env("NPM_TOKEN") || read_npmrc_value("//registry.npmjs.org/:_authToken")
  end

  @doc """
  Read a value from `.npmrc` files.

  Checks project-level first, then home-level.
  """
  @spec read_npmrc_value(String.t()) :: String.t() | nil
  def read_npmrc_value(key) do
    read_from_file(".npmrc", key) ||
      read_from_file(Path.join(System.user_home!(), ".npmrc"), key)
  end

  @doc "Parse an `.npmrc` file into a map of key-value pairs."
  @spec parse_npmrc(String.t()) :: %{String.t() => String.t()}
  def parse_npmrc(content) do
    content
    |> String.split("\n")
    |> Enum.reject(&(String.starts_with?(String.trim(&1), "#") or String.trim(&1) == ""))
    |> Enum.flat_map(&parse_line/1)
    |> Map.new()
  end

  @doc """
  Gets a config value with fallback to defaults.
  """
  @spec get(map(), String.t(), term()) :: term()
  def get(config, key, default \\ nil) do
    Map.get(config, key, default)
  end

  @doc """
  Merges multiple config maps (later overrides earlier).
  """
  @spec merge([map()]) :: map()
  def merge(configs) do
    Enum.reduce(configs, %{}, &Map.merge(&2, &1))
  end

  @doc """
  Loads config from all levels: project .npmrc then user .npmrc.
  Project values override user values.
  """
  @spec load(String.t()) :: map()
  def load(project_dir \\ ".") do
    user_config = read_file(Path.join(System.user_home!(), ".npmrc"))
    project_config = read_file(Path.join(project_dir, ".npmrc"))
    merge([user_config, project_config])
  end

  @doc """
  Returns the registry URL for a given scope, or the default.
  """
  @spec scoped_registry(map(), String.t()) :: String.t()
  def scoped_registry(config, scope) do
    key = "#{scope}:registry"
    Map.get(config, key, Map.get(config, "registry", "https://registry.npmjs.org"))
  end

  defp read_file(path) do
    case File.read(path) do
      {:ok, content} -> parse_npmrc(content)
      _ -> %{}
    end
  end

  defp read_from_file(path, key) do
    case File.read(path) do
      {:ok, content} -> parse_npmrc(content) |> Map.get(key)
      {:error, _} -> nil
    end
  end

  defp parse_line(line) do
    case String.split(String.trim(line), "=", parts: 2) do
      [key, value] -> [{String.trim(key), String.trim(value)}]
      _ -> []
    end
  end
end
