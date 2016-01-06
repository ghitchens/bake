defmodule Bake.Cli.Toolchain do
  use Bake.Cli.Menu

  alias Bake.Utils
  require Logger

  @switches [target: :string, all: :boolean, file: :string]

  defp menu do
    """
      get     - Install toolchain for target
    """
  end

  def main(args) do
    Bake.start
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)
    case cmd do
      ["get"] -> get(opts)
      _ -> invalid_cmd(cmd)
    end
  end

  # defp list do
  #   Bake.Shell.info "List installed toolchains"
  # end

  defp get(opts) do
    if opts[:target] == nil and opts[:all] == nil, do: raise """
      You must specify a target to install a toolchain for or pass --all to install toolchains for all targets
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
              Bake.Shell.info "=> Get toolchain for target #{target}"
              # First we need to find a local copy of the system for this target.
              # The system config.exs will contain the information about the toolchain
              recipe = v[:recipe]
              system_path = "#{mod.systems_path}/#{recipe}"
              if File.dir?(system_path) do
                {:ok, system_config} = "#{system_path}/config.exs"
                |> Bake.Config.Recipe.read!

                {username, tuple} =
                case system_config[:toolchain] do
                  {username, tuple, _version} -> {username, tuple}
                  ret -> ret
                end

                Bake.Api.Toolchain.get(%{tuple: tuple, username: username})
                |> get_resp(platform: platform, mod: mod)

              else
                Bake.Shell.error "System #{recipe} not downloaded. Please download the system first by running: "
                Bake.Shell.error "bake system get --target #{target}"
              end
            end)
        end
      {:error, e} ->
        Logger.debug "Bakefile Parse Error: #{inspect e}"
        Bake.Shell.info "No Bakefile Found"
    end
  end

  defp get_resp({:ok, %{status_code: code, body: body}}, opts) when code in 200..299 do
    %{data: %{path: path, host: host, target_tuple: tuple, username: username}} = Poison.decode!(body, keys: :atoms)

    platform = String.downcase(opts[:platform])
    mod = opts[:mod]

    case Bake.Api.request(:get, host <> "/" <> path, []) do
      {:ok, %{body: tar}} ->
        Bake.Shell.info "=> Toolchain #{username}/#{tuple} Downloaded"
        dir = mod.toolchains_path
        File.mkdir_p(dir)
        File.write!("#{dir}/#{tuple}.tar.gz", tar)
        Bake.Shell.info "=> Unpacking toolchain #{username}/#{tuple}"
        System.cmd("tar", ["zxf", "#{tuple}.tar.gz"], cd: dir)
        File.rm!("#{dir}/#{tuple}.tar.gz")

      {_, error} ->
        Bake.Shell.error "Error downloading system: #{inspect error}"
    end
  end

  defp get_resp({_, response}, _platform) do
    Bake.Shell.error("Failed to download toolchain")
    Bake.Utils.print_response_result(response)
  end

  # defp clean(opts) do
  #
  # end
end
