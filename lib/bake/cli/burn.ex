defmodule Bake.Cli.Burn do
  @menu "burn"
  @switches [target: :string, bakefile: :string]

  require Logger

  use Bake.Cli.Menu

  def menu do
    """
    """
  end

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    opts = Enum.into(opts, %{})
    Logger.debug "Opts: #{inspect opts}"
    {bakefile_path, target_config, target} = bakefile(Map.get(opts, :bakefile), Map.get(opts, :target))
    platform = target_config[:platform]
    Logger.debug "Target Config: #{inspect target_config}"
    otp_name = Path.dirname(bakefile_path) |> String.split("/") |> List.last
    adapter = adapter(platform)
    adapter.burn(bakefile_path, target_config, target, otp_name)
  end

end
