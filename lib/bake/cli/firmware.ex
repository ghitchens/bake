defmodule Bake.Cli.Firmware do
  use Bake.Cli.Menu

  require Logger

  defp menu do
    """
      --target
      --bakefile
    """
  end
  @menu "firmware"
  @switches [target: :string, all: :boolean, bakefile: :string]

  def main(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    all = opts[:all]
    if all, do: Bake.Shell.info """
    (Bake Warning) If you want to perform an action on all targets use
    bake #{@menu} command --target all
    """

    {bakefile, target_config, target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    otp_name = Path.dirname(bakefile) |> String.split("/") |> List.last
    Enum.each(target_config[:target], fn({target, v}) ->
      adapter.firmware(bakefile, target_config, target, otp_name)
    end)
  end
end
