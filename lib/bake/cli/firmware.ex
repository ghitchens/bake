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


    {bakefile, target_config, target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    otp_name = Path.dirname(bakefile) |> String.split("/") |> List.last
    Enum.each(target_config[:target], fn({target, v}) ->
      adapter.firmware(target_config, target, otp_name)
    end)
  end
end
