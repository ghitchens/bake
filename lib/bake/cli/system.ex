defmodule Bake.Cli.System do
  use Bake.Cli.Menu

  alias Bake.Utils
  require Logger

  @switches [target: :string, all: :boolean, file: :string]

  defp menu do
    """
      get       - Get a compiled system tar from bakeware.
      clean     - Remove a local system from disk
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
      ["clean"] -> clean(opts)
      _ -> invalid_cmd(cmd)
    end
  end

  defp get(opts) do
    target = check_target(opts)
    bakefile = check_bakefile(opts)

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
              Bake.Shell.info "=> Downloading system for target #{target}"
              Bake.Api.System.get(%{recipe: v[:recipe]})
              |> get_resp(platform: platform, mod: mod)
            end)
            Bake.Shell.info "=> Finished"
        end
      {:error, e} ->
        Bake.Shell.info "No Bakefile Found"
    end
  end

  defp get_resp({:ok, %{status_code: code, body: body}}, opts) when code in 200..299 do
    %{data: %{path: path, host: host, name: name}} = Poison.decode!(body, keys: :atoms)

    username = String.split(path, "/")
    |> List.first
    platform = String.downcase(opts[:platform])
    mod = opts[:mod]

    case Bake.Api.request(:get, host <> "/" <> path, []) do
      {:ok, %{body: tar}} ->
        Bake.Shell.info "=> System #{username}/#{name} Downloaded"
        dir = mod.systems_path <> "/#{username}"
        File.mkdir_p(dir)
        File.write!("#{dir}/#{name}.tar.gz", tar)
        Bake.Shell.info "=> Unpacking system #{username}/#{name}"
        System.cmd("tar", ["zxf", "#{name}.tar.gz"], cd: dir)
        File.rm!("#{dir}/#{name}.tar.gz")

      {_, error} ->
        Bake.Shell.error "Error downloading system: #{inspect error}"
    end
  end

  defp get_resp({_, response}, _platform) do
    Bake.Shell.error("Failed to download system")
    Bake.Utils.print_response_result(response)
  end

  def clean(opts) do
    target = check_target(opts)
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
              Bake.Shell.info "=> Cleaning system for target #{target}"
              dir = mod.systems_path <> "/#{v[:recipe]}"
              Bake.Shell.info "=>    Removing system #{v[:recipe]}"
              File.rm_rf!(dir)
            end)
            Bake.Shell.info "=> Finished"
        end
      {:error, e} ->
        Bake.Shell.info "No Bakefile Found"
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
