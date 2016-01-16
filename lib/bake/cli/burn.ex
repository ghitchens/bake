defmodule Bake.Cli.Burn do
  @menu "burn"
  @switches [target: :string, bakefile: :string]

  use Bake.Cli.Menu

  def menu do
    """
    """
  end

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    if opts[:target] == nil, do: raise """
      You must specify a target to burn
    """

    target = opts[:target]
    bakefile = opts[:bakefile] || System.cwd! <> "/Bakefile"

    case Bake.Config.read!(bakefile) do
      {:ok, config} ->
        case Bake.Config.filter_target(config, target) do
          [] -> Bake.Shell.info "Bakefile does not contain definition for target #{target}"
          target_config ->
            platform = target_config[:platform]
            |> Atom.to_string
            |> String.capitalize

            mod = Module.concat(Bake.Adapters, platform)

            otp_name = Path.dirname(bakefile) |> String.split("/") |> List.last
            #Enum.each(target_config[:target], fn({target, v}) ->
              mod.burn(target_config, target, otp_name)
            #end)

        end
      {:error, _e} ->
        Bake.Shell.info "No Bakefile Found"
    end
  end

end
