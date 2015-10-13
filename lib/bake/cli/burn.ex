defmodule Bake.Cli.Burn do
  use Bake.Cli.Menu
  alias Bake.Utils

  @switches []

  defp menu do
    """
    """
  end

  def main(args) do
    Bake.start
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    Bake.Shell.info "Burn Firmware"
  end

end
