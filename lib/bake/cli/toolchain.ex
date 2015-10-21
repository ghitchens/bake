defmodule Bake.Cli.Toolchain do
  use Bake.Cli.Menu

  alias Bake.Utils
  require Logger

  @switches [target: :string, all: :boolean, file: :string]

  defp menu do
    """
      get     - Install toolchain for target
      clean   - Uninstall local toolchain
    """
  end

  def main(args) do
    Bake.start
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)

    case cmd do
      ["get"] -> get(opts)
      ["clean"] -> clean(opts)
      _ -> invalid_cmd(cmd)
    end
  end

  defp list do
    Bake.Shell.info "List installed toolchains"
  end

  defp get(opts) do
    if opts[:target] == nil and opts[:all] == nil, do: raise """
      You must specify a target to install a toolchain for or pass --all to install toolchains for all targets
    """
    target = opts[:target] || {:all}
    bakefile = opts[:file] || System.cwd! <> "/Bakefile"
    case Bake.Config.read!(bakefile) do
      {:ok, config} ->
        case Bake.Config.filter_target(config, target) do
          [] -> Bake.Shell.info "Bakefile does not contain definition for target #{target}"
          target_config ->
            platform = target_config[:platform]
              |> to_string
              |> String.capitalize
            mod = Module.concat("Elixir.Bake.Adapters", platform)
              |> Module.concat("Toolchain")
            mod.get(target_config)
        end
      {:error, e} ->
        Logger.debug "Bakefile Parse Error: #{inspect e}"
        Bake.Shell.info "No Bakefile Found"
    end
  end

  defp clean(opts) do

  end
end
