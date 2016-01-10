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

    case cmd do
      ["get"] -> get(opts)
      ["clean"] -> clean(opts)
      _ -> invalid_cmd(cmd)
    end
  end

  defp get(opts) do
    {_, target_config, target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    Enum.each(target_config[:target], fn({target, v}) ->
      Bake.Shell.info "=> Downloading system for target #{target}"
      Bake.Api.System.get(%{recipe: v[:recipe]})
      |> get_resp(platform: platform, adapter: adapter)
    end)
  end

  defp get_resp({:ok, %{status_code: code, body: body}}, opts) when code in 200..299 do
    %{data: %{path: path, host: host, name: name}} = Poison.decode!(body, keys: :atoms)

    username = String.split(path, "/")
    |> List.first
    adapter = opts[:adapter]

    case Bake.Api.request(:get, host <> "/" <> path, []) do
      {:ok, %{status_code: code, body: tar}} when code in 200..299 ->
        Bake.Shell.info "=> System #{username}/#{name} Downloaded"
        dir = adapter.systems_path <> "/#{username}"
        File.mkdir_p(dir)
        File.write!("#{dir}/#{name}.tar.gz", tar)
        Bake.Shell.info "=> Unpacking system #{username}/#{name}"
        System.cmd("tar", ["zxf", "#{name}.tar.gz"], cd: dir)
        File.rm!("#{dir}/#{name}.tar.gz")

      {_, response} ->
        Bake.Shell.error("Failed to download system")
        Bake.Utils.print_response_result(response)
    end
  end

  defp get_resp({_, response}, _platform) do
    Bake.Shell.error("Failed to download system")
    Bake.Utils.print_response_result(response)
  end

  def clean(opts) do
    {_, target_config, target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    Enum.each(target_config[:target], fn({target, v}) ->
      Bake.Shell.info "=> Cleaning system for target #{target}"
      system_path = adapter.systems_path <> "/#{v[:recipe]}"
      if File.dir?(system_path) do
        Bake.Shell.info "=>    Removing system #{v[:recipe]}"
        File.rm_rf!(system_path)
      else
        Bake.Shell.info "System #{v[:recipe]} not downloaded"
      end
    end)
    Bake.Shell.info "=> Finished"
  end

end
