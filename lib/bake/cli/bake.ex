defmodule Bake.Cli.Bake do
  use Bake.Cli.Menu
  alias Bake.Utils

  @switches [file: :string, target: :string, all: :boolean]

  defp menu do
    """

    """
  end

  def main(args) do
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)
    if opts[:target] == nil and opts[:all] == nil, do: raise "You must specify a target to bake or pass --all to bake all targets"
    bakefile = opts[:file] || System.cwd! <> "/Bakefile"
    case File.exists?(bakefile) do
      true ->
        Bake.Shell.info "Compiling Firmware"
        Bale.Compiler.compile(bakefile)
      false -> Bake.Shell.info "No Bakefile Found"
    end
  end


end
