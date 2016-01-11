defmodule Bake.Cli.Toolchain do
  use Bake.Cli.Menu

  alias Bake.Utils
  require Logger

  @switches [target: :string, all: :boolean, file: :string]

  defp menu do
    """
      get     - Install toolchain for target
      clean   - Remove a local toolchain from disk
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

  # defp list do
  #   Bake.Shell.info "List installed toolchains"
  # end

  defp get(opts) do
    {_, target_config, target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    Enum.each(target_config[:target], fn({target, v}) ->
      Bake.Shell.info "=> Get toolchain for target #{target}"
      # First we need to find a local copy of the system for this target.
      # The system recipe.exs will contain the information about the toolchain
      recipe = v[:recipe]
      system_path = "#{adapter.systems_path}/#{recipe}"
      if File.dir?(system_path) do
        {:ok, system_config} = "#{system_path}/recipe.exs"
        |> Bake.Config.Recipe.read!

        {username, tuple, version} = system_config[:toolchain]
        Logger.debug "System Config: #{inspect system_config[:toolchain]}"
        Bake.Api.Toolchain.get(%{tuple: tuple, username: username, version: version})
        |> get_resp(platform: platform, adapter: adapter)

      else
        Bake.Shell.error "System #{recipe} not downloaded. Please download the system first by running: "
        Bake.Shell.error "bake system get --target #{target}"
      end
    end)
  end

  defp get_resp({:ok, %{status_code: code, body: body}}, opts) when code in 200..299 do
    %{data: %{path: path, host: host, target_tuple: tuple, username: username}} = Poison.decode!(body, keys: :atoms)

    adapter = opts[:adapter]

    Logger.debug "Toolchain: #{host <> "/" <> path}"

    case Bake.Api.request(:get, host <> "/" <> path, []) do
      {:ok, %{status_code: code, body: tar}} when code in 200..299 ->
        Bake.Shell.info "=> Toolchain #{username}/#{tuple} Downloaded"
        dir = adapter.toolchains_path
        File.mkdir_p(dir)
        File.write!("#{dir}/#{tuple}.tar.gz", tar)
        Bake.Shell.info "=> Unpacking toolchain #{username}/#{tuple}"
        System.cmd("tar", ["zxf", "#{tuple}.tar.gz"], cd: dir)
        File.rm!("#{dir}/#{tuple}.tar.gz")

      {_, response} ->
        Logger.debug "Response: #{inspect response}"
        Bake.Shell.error("Failed to download toolchain")
        Bake.Utils.print_response_result(response)
    end
  end

  defp get_resp({_, response}, _platform) do
    Bake.Shell.error("Failed to download toolchain")
    Bake.Utils.print_response_result(response)
  end

  def clean(opts) do
    {_, target_config, target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    Enum.each(target_config[:target], fn({target, v}) ->
      Bake.Shell.info "=> Cleaning toolchain for target #{target}"

      system_path = adapter.systems_path <> "/#{v[:recipe]}"
      if File.dir?(system_path) do
        {:ok, system_config} = "#{system_path}/recipe.exs"
        |> Bake.Config.Recipe.read!

        {username, toolchain_tuple, _toolchain_version} = system_config[:toolchain]
        host_platform = BakeUtils.host_platform
        host_arch = BakeUtils.host_arch
        toolchain_name = "#{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch}"

        toolchains = File.ls!(adapter.toolchains_path)
        toolchain_name = Enum.find(toolchains, &(String.starts_with?(&1, toolchain_name)))
        toolchain_path = "#{adapter.toolchains_path}/#{toolchain_name}"
        if File.dir?(toolchain_path) do
          Bake.Shell.info "=>    Removing toolchain #{toolchain_path}"
          File.rm_rf!(toolchain_path)
        else
          raise "Toolchain #{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch} not downloaded"
        end
      else
        Bake.Shell.info "System #{v[:recipe]} not downloaded"
      end
    end)
    Bake.Shell.info "=> Finished"
  end

end
