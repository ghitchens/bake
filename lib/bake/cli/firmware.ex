defmodule Bake.Cli.Firmware do
  @menu "firmware"
  @switches [target: :string, all: :boolean, bakefile: :string]

  use Bake.Cli.Menu
  require Logger

  def menu do
    """
      --target
      --bakefile
    """
  end

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    opts = Enum.into(opts, %{})
    if Map.get(opts, :all), do: Bake.Shell.info """
    (Bake Warning) If you want to perform an action on all targets use
    bake #{@menu} command --target all
    """

    {bakefile, target_config, _target} = bakefile(Map.get(opts, :bakefile), Map.get(opts, :target))
    platform = target_config[:platform]
    adapter = adapter(platform)
    otp_name = Path.dirname(bakefile) |> String.split("/") |> List.last
    Enum.each(target_config[:target], fn({target, _v}) ->
      adapter.firmware(bakefile, target_config, target, otp_name)
    end)
  end
end
