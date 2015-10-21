defmodule Bake.Cli.System do
  use Bake.Cli.Menu

  alias Bake.Utils
  require Logger

  @switches [target: :string, all: :boolean, file: :string]

  defp menu do
    """
      compile   - Remote compile the system, must specify a --target
    """
  end

  def main(args) do
    Bake.start
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)

    if opts[:target] == nil and opts[:all] == nil, do: raise """
      You must specify a target to compile or pass --all to compile systems for all targets
    """

    case cmd do
      ["compile"] -> compile(opts)
      _ -> invalid_cmd(cmd)
    end
  end

  defp compile(opts) do
    # Prevent a defined target called :all
    #  from accidentially compiling all targets
    target = opts[:target] || {:all}
    bakefile = opts[:file] || System.cwd! <> "/Bakefile"
    case Bake.Config.read!(bakefile) do
      {:ok, config} ->
        case Bake.Config.filter_target(config, target) do
          [] -> Bake.Shell.info "Bakefile does not contain definition for target #{target}"
          target_config -> Bake.Compiler.System.compile(target_config)
        end
      {:error, e} ->
        Bake.Shell.info "No Bakefile Found"
    end
  end
end
