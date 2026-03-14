defmodule Mix.Tasks.Npm.Exec do
  @shortdoc "Execute a package binary"

  @moduledoc """
  Execute a binary from `node_modules/.bin/`.

      mix npm.exec eslint .
      mix npm.exec tsc --version

  Similar to `npx` but only runs locally installed binaries.
  """

  use Mix.Task

  @impl true
  def run([command | args]) do
    Application.ensure_all_started(:req)

    bin_path = Path.join("node_modules/.bin", command)

    if File.exists?(bin_path) do
      execute(bin_path, args)
    else
      Mix.shell().error("Binary #{command} not found in node_modules/.bin/")
      Mix.shell().info("Run `mix npm.install` to install packages.")
    end
  end

  def run([]) do
    bin_dir = "node_modules/.bin"

    if File.exists?(bin_dir) do
      case File.ls(bin_dir) do
        {:ok, entries} ->
          Mix.shell().info("Available binaries:")
          Enum.each(Enum.sort(entries), &Mix.shell().info("  #{&1}"))

        {:error, _} ->
          Mix.shell().info("No binaries found.")
      end
    else
      Mix.shell().info("No node_modules/.bin/ directory. Run `mix npm.install` first.")
    end
  end

  defp execute(bin_path, args) do
    full_command = Enum.join([bin_path | args], " ")

    port =
      Port.open({:spawn, full_command}, [
        :binary,
        :exit_status,
        :stderr_to_stdout
      ])

    stream_port(port)
  end

  defp stream_port(port) do
    receive do
      {^port, {:data, data}} ->
        IO.write(data)
        stream_port(port)

      {^port, {:exit_status, 0}} ->
        :ok

      {^port, {:exit_status, code}} ->
        Mix.shell().error("Exited with code #{code}")
        {:error, {:exit, code}}
    end
  end
end
