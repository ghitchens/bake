defmodule Bake.Cli.System do
  use Bake.Cli.Menu

  alias Bake.Utils
  require Logger

  @switches [target: :string, all: :boolean, file: :string]

  defp menu do
    """
      get       - Get a compiled system tar from bakeware.
    """
  end

  def main(args) do
    Bake.start
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)

    if opts[:target] == nil and opts[:all] == nil, do: raise """
      You must specify a target to compile or pass --all to compile systems for all targets
    """

    case cmd do
      ["get"] -> get(opts)
      _ -> invalid_cmd(cmd)
    end
  end

  defp get(opts) do
    if opts[:target] == nil and opts[:all] == nil, do: raise """
      You must specify a target to install a system for or pass --all to install systems for all targets
    """
    target = opts[:target] || {:all}
    bakefile = opts[:file] || System.cwd! <> "/Bakefile"
    case Bake.Config.read!(bakefile) do
      {:ok, config} ->
        case Bake.Config.filter_target(config, target) do
          [] -> Bake.Shell.info "Bakefile does not contain definition for target #{target}"
          target_config ->
            platform = target_config[:platform]
              |> to_string
              |> String.capitalize
            mod = Module.concat("Elixir.Bake.Adapters", platform)

            Enum.each(target_config[:target], fn({target, v}) ->
              Bake.Shell.info "=> Downloading System for target #{target}"
              Bake.Api.System.get(%{recipe: v[:recipe]})
              |> get_resp(platform)
            end)
            Bake.Shell.info "=> Finished"
        end
      {:error, e} ->
        Bake.Shell.info "No Bakefile Found"
    end
  end

  defp get_resp({:ok, %{body: body}}, platform) do
    %{data: %{path: path, host: host, name: name}} = Poison.decode!(body, keys: :atoms)

    username = String.split(path, "/")
    |> List.first
    platform = String.downcase platform

    case Bake.Api.request(:get, host <> "/" <> path, []) do
      {:ok, %{body: tar}} ->
        Bake.Shell.info "=> System #{username}/#{name} Downloaded"
        dir = BakeUtils.bake_home <> "/#{platform}/systems/#{username}"
        File.mkdir_p(dir)
        File.write!("#{dir}/#{name}.tar.gz", tar)
        Bake.Shell.info "=> Unpacking System #{username}/#{name}"
        System.cmd("tar", ["zxf", "#{name}.tar.gz"], cd: dir)
        File.rm!("#{dir}/#{name}.tar.gz")

      {_, error} ->
        raise "Error downloading system: #{inspect error}"
    end
  end

  # defp compile(opts) do
  #   # Prevent a defined target called :all
  #   #  from accidentially compiling all targets
  #   target = opts[:target] || {:all}
  #   bakefile = opts[:file] || System.cwd! <> "/Bakefile"
  #   case Bake.Config.read!(bakefile) do
  #     {:ok, config} ->
  #       case Bake.Config.filter_target(config, target) do
  #         [] -> Bake.Shell.info "Bakefile does not contain definition for target #{target}"
  #         target_config -> Bake.Compiler.System.compile(target_config)
  #       end
  #     {:error, e} ->
  #       Bake.Shell.info "No Bakefile Found"
  #   end
  # end
end
