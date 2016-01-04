defmodule Bake.Cli.Firmware do
  use Bake.Cli.Menu

  require Logger

  defp menu do
    """
      --target
      --bakefile
    """
  end

  @switches [target: :string, bakefile: :string]

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    if opts[:target] == nil and opts[:all] == nil, do: raise """
      You must specify a target to compile or pass --all to compile systems for all targets
    """

    target = opts[:target] || {:all}
    bakefile = opts[:bakefile] || System.cwd! <> "/bakefile.exs"

    case Bake.Config.read!(bakefile) do
      {:ok, config} ->
        case Bake.Config.filter_target(config, target) do
          [] -> Bake.Shell.info "Bakefile does not contain definition for target #{target}"
          target_config ->
            platform = target_config[:platform]
            |> Atom.to_string
            |> String.capitalize

            mod = Module.concat(Bake.Adapters, platform)
            |> Module.concat(Assemble)
            otp_name = Path.dirname(bakefile) |> String.split("/") |> List.last
            mod.firmware(target_config, target, otp_name)
        end
      {:error, e} ->
        Bake.Shell.info "No Bakefile Found"
    end
  end
end
