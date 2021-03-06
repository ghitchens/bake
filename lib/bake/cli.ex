defmodule Bake.Cli do
  @switches [version: :boolean]
  @menu "bake"

  use Bake.Cli.Menu
  alias Bake.Cli
  require Logger


  def menu do
    """
      help module - Show help for a module
      global      - Control global variables
      daemon      - Control the local bake daemon
      user        - User management commands
      recipe      - Recipe Options
      system      - Target system options
      toolchain   - Toolchain options
      firmware    - Target Firmware options
      burn        - Burn firmware to SD / Image
    """
  end

  def main(args) do
    Bake.start
    case args do
      ["help" | cmd] -> Cli.Help.main(cmd)
      ["global" | cmd] -> Cli.Global.main(cmd)
      ["daemon" | cmd] -> Cli.Daemon.main(cmd)
      ["user" | cmd] -> Cli.User.main(cmd)
      ["recipe" | cmd] -> Cli.Recipe.main(cmd)
      ["system" | cmd] -> Cli.System.main(cmd)
      ["toolchain" | cmd] -> Cli.Toolchain.main(cmd)
      ["firmware" | cmd] -> Cli.Firmware.main(cmd)
      ["clean" | cmd] -> clean(cmd)
      ["burn" | cmd] -> Cli.Burn.main(cmd)
      cmd -> switch(cmd, args)
    end
  end

  def switch(_, ["--version"]) do
    Bake.Shell.info "Bake CLI Version: #{Bake.Utils.cli_version}"
  end

  def switch(["update"], _) do
    Bake.Shell.info "=> Checking for update"

    case Bake.Api.Update.get do
      {:ok, %{body: body}} ->
        case Poison.decode(body, keys: :atoms) do
          {:ok, %{source: _source, version: version} = update} ->
            Version.compare(version, Bake.Utils.cli_version)
            |> update_check(update)

          {:error, error} ->
            update_error(error)
        end
      {_, error} ->
        update_error(error)
    end
  end

  def switch(cmd, _), do: invalid_cmd(cmd)

  defp clean(opts) do
    {_, target_config, _target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    adapter.clean
  end

  defp update_check(:gt, %{source: source, version: version}) do
    Bake.Shell.info "==> Downloading bake v#{version}"
    HTTPoison.request(
      :get,
      source,
      "",
      [],
      timeout: Bake.Api.timeout
    ) |> update
  end
  defp update_check(_, _) do
    Bake.Shell.info "==> bake #{Bake.Utils.cli_version} is at the latest version"
  end

  defp update({:ok, %{body: tar}}) do
    Bake.Shell.info "==> Unpacking Update"
    %{"bake" => bake} = Bake.Utils.Tar.unpack(tar, :compressed)
    File.write!(Bake.Utils.escript_path, bake)
    Bake.Shell.info "==> Update Complete"
  end

  defp update({_, error}) do
    update_error(error)
  end

  defp update_error(error) do
    Bake.Shell.info "Error downloading update: #{inspect error}"
  end
end
