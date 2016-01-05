defmodule Bake.Cli do
  use Bake.Cli.Menu
  alias Bake.Cli
  require Logger

  @switches [version: :string]

  def menu do
    """
      daemon    - Control the local bake daemon
      user      - User management commands
      recipe    - Recipe Options
      system    - Target system options
      toolchain - Toolchain options
      firmware  - Target Firmware options
      burn      - Install language helper functions
    """
  end

  def main(args) do
    Bake.start
    case args do
      ["daemon" | cmd] -> Cli.Daemon.main(cmd)
      ["user" | cmd] -> Cli.User.main(cmd)
      ["recipe" | cmd] -> Cli.Recipe.main(cmd)
      ["system" | cmd] -> Cli.System.main(cmd)
      ["toolchain" | cmd] -> Cli.Toolchain.main(cmd)
      ["firmware" | cmd] -> Cli.Firmware.main(cmd)
      ["burn" | cmd] -> Cli.Burn.main(cmd)
      cmd -> switch(cmd, args)
    end
  end

  def switch(_, ["--version"]) do
    Bake.Shell.info "Bake CLI Version: #{Bake.Utils.cli_version}"
  end

  def switch(["update"], _) do
    case Bake.Api.Update.get do
      {:ok, %{body: body}} ->
        case Poison.decode(body, keys: :atoms) do
          {:ok, %{source: source}} ->
            Bake.Shell.info "Downloading update"
            HTTPoison.request(
              :get,
              source,
              "",
              [],
              timeout: @timeout
            ) |> update
          {:error, error} ->
            update_error(error)
        end
      {_, error} ->
        update_error(error)
    end
  end

  def switch(cmd, _), do: invalid_cmd(cmd)

  # def bake(args) do
  #   Cli.Bake.main(args)
  # end

  defp update({:ok, %{body: tar}}) do
    Bake.Shell.info "Unpacking Update"
    %{"bake" => bake} = BakeUtils.Tar.unpack(tar, :compressed)
    File.write!(Bake.Utils.escript_path, bake)
    Bake.Shell.info "Update Complete"
    #Logger.debug "Files: #{inspect files}"
  end

  defp update({_, error}) do
    update_error(error)
  end

  defp update_error(error) do
    Bake.Shell.info "Error downloading update: #{inspect error}"
  end
end
