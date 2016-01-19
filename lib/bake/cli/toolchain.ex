defmodule Bake.Cli.Toolchain do
  @menu "toolchain"
  @switches [target: :string, all: :boolean, file: :string]

  use Bake.Cli.Menu

  def menu do
    """
      get     - Install toolchain for target
      clean   - Remove a local toolchain from disk
    """
  end

  def main(args) do
    Bake.start
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)
    opts = Enum.into(opts, %{})
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
    all_warn(opts)
    {bakefile_path, target_config, target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)

    lock_path = bakefile_path
    |> Path.dirname

    lock_path = lock_path <> "/Bakefile.lock"

    if File.exists?(lock_path) do
      # The exists. Check to see if it contains a lock for our target
      lock_file = Bake.Config.Lock.read(lock_path)
      lock_targets = lock_file[:targets]
      Enum.each(target_config[:target], fn({target, v}) ->
        Bake.Shell.info "=> Get toolchain for target #{target}"
        # First we need to find a local copy of the system for this target.
        # The system recipe.exs will contain the information about the toolchain
          case Keyword.get(lock_targets, target) do
            nil ->
              # Target is not locked, download latest version
              {recipe, _} = v[:recipe]
              Bake.Shell.error_exit """
              System #{recipe} not downloaded. Please download the system first by running: "
              > bake system get --target #{target}
              """
            [{recipe, version}] ->
              system_path = "#{adapter.systems_path}/#{recipe}-#{version}"
              case Bake.Config.Recipe.read!("#{system_path}/recipe.exs") do
                {:ok, system_config} ->
                  {username, tuple, version} = system_config[:toolchain]
                  host_platform = Bake.Utils.host_platform
                  host_arch = Bake.Utils.host_arch
                  toolchain = "#{username}-#{tuple}-#{host_platform}-#{host_arch}-v#{version}"
                  toolchain_path = "#{adapter.toolchains_path}/#{toolchain}"
                  if File.dir?(toolchain_path) do
                    Bake.Shell.info "==> Toolchain #{toolchain} up to date"
                  else
                    Bake.Shell.info "==> Downloading toolchain for target #{target}"
                    Bake.Api.Toolchain.get(%{tuple: tuple, username: username, version: version})
                    |> get_resp(platform: platform, adapter: adapter)
                  end
                {:error, _} ->
                  Bake.Shell.error_exit """
                  System #{recipe} not downloaded. Please download the system first by running: "
                  > bake system get --target #{target}
                  """
              end
          end
      end)
    else
      # The lockfile doesn't exist. Download latest version
      Bake.Shell.error_exit """
      System for target #{target} not locked. Please get the system first by running
      > bake system get --target #{target}
      """
    end
  end

  defp get_resp({:ok, %{status_code: code, body: body}}, opts) when code in 200..299 do
    %{data: %{path: path, host: host, target_tuple: tuple, username: username}} = Poison.decode!(body, keys: :atoms)

    adapter = opts[:adapter]

    case Bake.Api.request(:get, host <> "/" <> path, []) do
      {:ok, %{status_code: code, body: tar}} when code in 200..299 ->
        Bake.Shell.info "==> Toolchain #{username}/#{tuple} Downloaded"
        dir = adapter.toolchains_path
        File.mkdir_p(dir)
        Bake.Shell.info "==> Unpacking toolchain #{username}/#{tuple}"
        case :erl_tar.extract({:binary, tar}, [{:cwd, dir}, :compressed]) do
          :ok -> nil
          {:error, _error} ->
            File.write!("#{dir}/#{tuple}.tar.xz", tar)
            case System.cmd("tar", ["xf", "#{tuple}.tar.xz"], cd: dir) do
              {_, 0} -> File.rm_rf("#{dir}/#{tuple}.tar.xz")
              {error, code} ->
                File.rm_rf("#{dir}/#{tuple}.tar.xz")
                Logger.debug "Compression Error 2: #{inspect error} #{inspect code}"
                Bake.Shell.error_exit """
                Error extracting toolchain #{username}/#{tuple}
                """
            end
        end
      {_, response} ->
        Logger.debug "Response: #{inspect response}"
        Bake.Shell.info "Failed to download toolchain"
        Bake.Utils.print_response_result(response)
        Bake.Shell.error_exit "Please chect to ensure that this toolchain is available for your host"
    end
  end

  defp get_resp({_, response}, _platform) do
    Bake.Shell.error_exit "Failed to download toolchain"
    Bake.Utils.print_response_result(response)
  end

  def clean([all: true] = opts) do
    {_bakefile_path, target_config, _target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    Bake.Shell.warn "You are about to clean all toolchains for #{platform}"
    if Bake.Shell.yes?("Proceed?") do
      File.rm_rf!(adapter.toolchains_path)
      Bake.Shell.info "All #{platform} toolchains have been removed"
    end
  end

  def clean(opts) do
    {bakefile_path, target_config, _target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)

    lock_path = bakefile_path
    |> Path.dirname

    lock_path = lock_path <> "/Bakefile.lock"

    if File.exists?(lock_path) do

      lock_file = Bake.Config.Lock.read(lock_path)
      lock_targets = lock_file[:targets]

      Enum.each(target_config[:target], fn({target, _v}) ->
        Bake.Shell.info "=> Cleaning toolchain for target #{target}"
        case Keyword.get(lock_targets, target) do
          nil ->
            Bake.Shell.warn """
            System not downloaded. Please download the system first by running: "
            > bake system get --target #{target}
            """
            Bake.Shell.error_exit ""
          [{recipe, version}] ->
            system_path = "#{adapter.systems_path}/#{recipe}-#{version}"
            {:ok, system_config} = "#{system_path}/recipe.exs"
            |> Bake.Config.Recipe.read!

            {username, toolchain_tuple, version} = system_config[:toolchain]
            host_platform = Bake.Utils.host_platform
            host_arch = Bake.Utils.host_arch
            toolchain_name = "#{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch}-v#{version}"
            toolchain_path = "#{adapter.toolchains_path}/#{toolchain_name}"
            if File.dir?(toolchain_path) do
              Bake.Shell.info "==> Removing toolchain #{toolchain_path}"
              File.rm_rf!(toolchain_path)
            else
              Bake.Shell.error_exit "Toolchain #{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch} not downloaded"
            end
        end
      end)
    end
  end

end
