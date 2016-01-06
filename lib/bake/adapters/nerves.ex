defmodule Bake.Adapter.Nerves do
  @behaviour Bake.Adapter

  require Logger

  def system_get(config) do

  end

  def firmware(config, target, otp_name) do
    Bake.Shell.info "Assembling firmware for target #{target}"
    target_config = config
    |> Keyword.get(:target)
    |> Keyword.get(String.to_atom(target))
    recipe = target_config[:recipe]
    # TODO: Need to get locked version from the bakefile.lock

    # Check to ensure that the system is available in NERVES_HOME
    nerves_home = System.get_env("NERVES_HOME") || "~/.nerves"
    system_path = "#{nerves_home}/systems/#{recipe}"
    |> Path.expand
    #Logger.debug "Path: #{inspect system_path}"
    if File.dir?(system_path) do
      #Logger.debug "System #{recipe} Found"
    else
      raise "System #{inspect recipe} not downloaded"
    end
    # Read the recipe config from the system
    {:ok, system_config} = "#{system_path}/config.exs"
    |> Bake.Config.Recipe.read!

    rel2fw = "#{system_path}/scripts/rel2fw.sh"

    #Logger.debug "System Config: #{inspect system_config}"
    # Toolchain
    {toolchain_tuple, _toolchain_version} = system_config[:toolchain]

    {host_arch, _} = System.cmd("uname", ["-m"])
    host_arch = String.strip(host_arch)

    {host_os, _} = System.cmd("uname", ["-s"])
    host_os = String.strip(host_os)
    
    toolchain_path = "#{nerves_home}/toolchains/#{toolchain_tuple}-#{host_os}-#{host_arch}"
    |> Path.expand

    if File.dir?(toolchain_path) do
      #Logger.debug "Toolchain #{toolchain_tuple} Found"
    else
      raise "Toolchain #{toolchain_tuple}-#{host_arch}-#{host_os} not downloaded"
    end

    stream = IO.binstream(:standard_io, :line)
    env = [
      {"NERVES_APP", File.cwd!},
      {"NERVES_TOOLCHAIN", toolchain_path},
      {"NERVES_SYSTEM", system_path},
      {"MIX_ENV", System.get_env("MIX_ENV") || "dev"}
    ]
    cmd = """
    source nerves-env.sh &&
    cd #{File.cwd!} &&
    mix release &&
    sh #{rel2fw} rel/#{otp_name} _images/#{otp_name}.fw
    """ |> remove_newlines
    Porcelain.shell(cmd, dir: system_path, env: env, out: stream)
  end

  def burn(config, target, otp_name) do

  end

  defp remove_newlines(string) do
    string |> String.strip |> String.replace("\n", " ")
  end
end
