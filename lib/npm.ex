defmodule NPM do
  @moduledoc """
  npm package manager for Elixir.

  Resolves, fetches, and installs npm packages using Mix tasks.
  Dependencies are declared in `package.json` and locked in `npm.lock`.

  ## Mix tasks

      mix npm.install           # Install all deps from package.json
      mix npm.install lodash    # Add latest version
      mix npm.install lodash@^4.0  # Add with specific range
      mix npm.get               # Fetch locked deps without resolving

  Packages are cached globally in `~/.npm_ex/cache/` and linked into
  `node_modules/` via symlinks (macOS/Linux) or copies (Windows).
  """

  @node_modules "node_modules"

  @doc """
  Install all dependencies from `package.json`.

  Resolves versions using the PubGrub solver, writes `npm.lock`,
  populates the global cache, and links into `node_modules/`.
  """
  @spec install :: :ok | {:error, term()}
  def install do
    case NPM.PackageJSON.read() do
      {:ok, deps} -> do_install(deps)
      error -> error
    end
  end

  @doc """
  Add a package to `package.json` and install all dependencies.
  """
  @spec install(String.t(), String.t()) :: :ok | {:error, term()}
  def install(name, range \\ "latest") do
    range = if range == "latest", do: resolve_latest(name), else: range

    with range_str when is_binary(range_str) <- range,
         :ok <- NPM.PackageJSON.add_dep(name, range_str),
         {:ok, deps} <- NPM.PackageJSON.read() do
      do_install(deps)
    end
  end

  @doc """
  Fetch locked dependencies without re-resolving.

  Reads `npm.lock` and populates the global cache and `node_modules/`
  for any missing packages.
  """
  @spec get :: :ok | {:error, term()}
  def get do
    case NPM.Lockfile.read() do
      {:ok, lockfile} when lockfile == %{} ->
        Mix.shell().info("No npm.lock found, run `mix npm.install` first.")
        :ok

      {:ok, lockfile} ->
        link_from_lockfile(lockfile)

      error ->
        error
    end
  end

  # --- Private ---

  defp do_install(deps) when map_size(deps) == 0 do
    Mix.shell().info("No npm dependencies found in package.json.")
    :ok
  end

  defp do_install(deps) do
    Mix.shell().info("Resolving npm dependencies...")
    NPM.Resolver.clear_cache()

    case NPM.Resolver.resolve(deps) do
      {:ok, resolved} ->
        lockfile = build_lockfile(resolved)
        NPM.Lockfile.write(lockfile)
        link_from_lockfile(lockfile)

      {:error, message} ->
        Mix.shell().error("Resolution failed:\n#{message}")
        {:error, :resolution_failed}
    end
  end

  defp link_from_lockfile(lockfile) do
    log_fetching(lockfile)

    case NPM.Linker.link(lockfile, @node_modules) do
      :ok -> report_installed(lockfile)
      error -> error
    end
  end

  defp log_fetching(lockfile) do
    Enum.each(lockfile, fn {name, entry} ->
      unless NPM.Cache.cached?(name, entry.version) do
        Mix.shell().info("  Fetching #{name}@#{entry.version}")
      end
    end)
  end

  defp report_installed(lockfile) do
    count = map_size(lockfile)
    Mix.shell().info("Installed #{count} npm package#{if count != 1, do: "s", else: ""}.")
    :ok
  end

  defp build_lockfile(resolved) do
    for {name, version_str} <- resolved, into: %{} do
      {:ok, packument} = NPM.Registry.get_packument(name)
      info = Map.fetch!(packument.versions, version_str)

      {name,
       %{
         version: version_str,
         integrity: info.dist.integrity,
         tarball: info.dist.tarball,
         dependencies: info.dependencies
       }}
    end
  end

  defp resolve_latest(name) do
    case NPM.Registry.get_packument(name) do
      {:ok, packument} -> latest_stable_range(packument)
      {:error, reason} -> {:error, reason}
    end
  end

  defp latest_stable_range(packument) do
    packument.versions
    |> Map.keys()
    |> Enum.flat_map(&parse_stable_version/1)
    |> Enum.sort(Version)
    |> List.last()
    |> case do
      nil -> {:error, :no_versions}
      v -> "^#{v}"
    end
  end

  defp parse_stable_version(v) do
    case Version.parse(v) do
      {:ok, ver} -> if ver.pre == [], do: [ver], else: []
      :error -> []
    end
  end
end
