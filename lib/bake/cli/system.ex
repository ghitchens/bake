defmodule Bake.Cli.System do
  @menu "system"
  @switches [target: :string, all: :boolean, file: :string]

  use Bake.Cli.Menu
  require Logger

  def menu do
    """
      get       - Get a compiled system tar from bakeware.
      update    - Update a system
      clean     - Remove a local system from disk
    """
  end

  def main(args) do
    Bake.start
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)

    case cmd do
      ["get"] -> get(opts)
      ["update"] -> update(opts)
      ["clean"] -> clean(opts)
      _ -> invalid_cmd(cmd)
    end
  end

  defp get(opts) do
    all_warn(opts)
    {bakefile_path, target_config, _target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)

    lock_path = bakefile_path
    |> Path.dirname
    lock_path = lock_path <> "/Bakefile.lock"

    Enum.each(target_config[:target], fn({target, v}) ->
      Bake.Shell.info "=> Checking system for target #{target}"
      if File.exists?(lock_path) do
        # The exists. Check to see if it contains a lock for our target
        lock_file = Bake.Config.Lock.read(lock_path)
        lock_targets = lock_file[:targets]
        case Keyword.get(lock_targets, target) do
          nil ->
            # Target is not locked, download latest version
            {recipe, version} = v[:recipe]
            Bake.Api.System.get(%{recipe: recipe, requirement: version})
            |> get_resp(platform: platform, adapter: adapter, lock_file: lock_path, target: target)
          [{recipe, version}] ->
            Bake.Api.System.get(%{recipe: recipe, version: version})
            |> get_resp(platform: platform, adapter: adapter, lock_file: lock_path, target: target)
        end
      else
        # The lockfile doesn't exist. Download latest version
        {recipe, version} = v[:recipe]
        Bake.Api.System.get(%{recipe: recipe, requirement: version})
        |> get_resp(platform: platform, adapter: adapter, lock_file: lock_path, target: target)
      end
    end)
  end

  defp update(opts) do
    all_warn(opts)
    {bakefile_path, target_config, _target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)

    lock_path = bakefile_path
    |> Path.dirname
    lock_path = lock_path <> "/Bakefile.lock"

    Enum.each(target_config[:target], fn {target, v} ->
      {recipe, version} = v[:recipe]
      Bake.Api.System.get(%{recipe: recipe, requirement: version})
      |> get_resp(platform: platform, adapter: adapter, lock_file: lock_path, target: target)
    end)
  end

  defp get_resp({:ok, %{status_code: code, body: body}}, opts) when code in 200..299 do
    %{data: %{path: path, host: host, name: name, version: version, username: username}} = Poison.decode!(body, keys: :atoms)

    adapter = opts[:adapter]
    system_path = "#{adapter.systems_path}/#{username}/#{name}-#{version}"
    lock_file = opts[:lock_file]
    target = opts[:target]

    if File.dir?(system_path) do
      Bake.Shell.info "=> System #{username}/#{name} at #{version} up to date"
      Bake.Config.Lock.update(lock_file, [targets: [{target, ["#{username}/#{name}": version]}]])
    else
      Bake.Shell.info "=> Downloading system #{username}/#{name}-#{version}"
      case Bake.Api.request(:get, host <> "/" <> path, []) do
        {:ok, %{status_code: code, body: tar}} when code in 200..299 ->
          Bake.Shell.info "=> System #{username}/#{name}-#{version} downloaded"
          dir = adapter.systems_path <> "/#{username}"
          File.mkdir_p(dir)
          File.write!("#{dir}/#{name}-#{version}.tar.gz", tar)
          Bake.Shell.info "=> Unpacking system #{username}/#{name}-#{version}"
          System.cmd("tar", ["zxf", "#{name}-#{version}.tar.gz"], cd: dir)
          File.rm!("#{dir}/#{name}-#{version}.tar.gz")
          Bake.Config.Lock.update(lock_file, [targets: [{target, ["#{username}/#{name}": version]}]])
        {_, response} ->
          Bake.Shell.error("Failed to download system")
          Bake.Utils.print_response_result(response)
      end
    end
  end

  defp get_resp({_, response}, _platform) do
    Bake.Shell.error("Failed to download system")
    Bake.Utils.print_response_result(response)
  end

  def clean([all: true] = opts) do
    {_bakefile_path, target_config, _target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)
    Bake.Shell.info "You are about to clean all systems for #{platform}"
    if Bake.Shell.yes?("Proceed?") do
      File.rm_rf!(adapter.systems_path)
      Bake.Shell.info "All #{platform} systems have been removed"
    end
  end

  def clean(opts) do
    {bakefile_path, target_config, _target} = bakefile(opts[:bakefile], opts[:target])
    platform = target_config[:platform]
    adapter = adapter(platform)

    lock_path = bakefile_path
    |> Path.dirname
    lock_path = lock_path <> "/Bakefile.lock"

    Enum.each(target_config[:target], fn({target, v}) ->
      {recipe, _version} = v[:recipe]
      if File.exists?(lock_path) do
        # The exists. Check to see if it contains a lock for our target
        lock_file = Bake.Config.Lock.read(lock_path)
        lock_targets = lock_file[:targets]
        case Keyword.get(lock_targets, target) do
          nil ->
            Bake.Shell.info "Target does not contain locked #{recipe}"
          [{recipe, version}] ->
            system_path = adapter.systems_path <> "/#{recipe}-#{version}"
            if File.dir?(system_path) do
              Bake.Shell.info "=> Cleaning system for target #{target}"
              Bake.Shell.info "==> Removing system #{recipe}-#{version}"
              File.rm_rf!(system_path)
            else
              Bake.Shell.info "System #{recipe}-#{version} not downloaded"
            end
        end
      else
        # The lockfile doesn't exist. Download latest version
        Bake.Shell.info "Target does not contain locked #{recipe}"
      end
    end)
  end

end
