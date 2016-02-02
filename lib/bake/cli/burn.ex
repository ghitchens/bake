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
    {opts, _, fwup_opts} = OptionParser.parse(args, switches: @switches)
    opts = Enum.into(opts, %{})
    fwup_opts = Enum.reduce(fwup_opts, "", fn({k, v}, acc) -> "#{acc} #{k} #{v}" end)

    {bakefile_path, target_config, target} = bakefile(Map.get(opts, :bakefile), Map.get(opts, :target))
    platform = target_config[:platform]

    otp_name = Path.dirname(bakefile_path) |> String.split("/") |> List.last
    adapter = adapter(platform)

    adapter.burn(bakefile_path, target_config, target, otp_name, fwup_opts)
  end

end
