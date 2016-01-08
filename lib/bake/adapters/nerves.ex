defmodule Bake.Adapters.Nerves do
  import BakeUtils.Cli.Config, only: [encode_term: 1, decode_term: 1, decode_elixir: 1]
  @behaviour Bake.Adapter

  @nerves_home System.get_env("NERVES_HOME") || "~/.nerves"

  require Logger

  def systems_path, do: "#{@nerves_home}/systems/" |> Path.expand
  def toolchains_path, do: "#{@nerves_home}/toolchains/" |> Path.expand

  def firmware(config, target, otp_name) do
    Bake.Shell.info "=> Building firmware for target #{target}"
    {toolchain_path, system_path} = config_env(config, target)
    rel2fw = "#{system_path}/scripts/rel2fw.sh"
    stream = IO.binstream(:standard_io, :line)
    env = [
      {"NERVES_APP", File.cwd!},
      {"NERVES_TOOLCHAIN", toolchain_path},
      {"NERVES_SYSTEM", system_path},
      {"NERVES_TARGET", to_string(target)},
      {"MIX_ENV", System.get_env("MIX_ENV") || "dev"}
    ]

    cmd = """
    source #{system_path}/scripts/nerves-env-helper.sh #{system_path} &&
    cd #{File.cwd!} &&
    mix local.hex --force &&
    mix local.rebar --force &&
    """

    #check for the env cache
    if File.dir?("#{File.cwd!}/_build") do
      # Load the env file
      case File.read("#{File.cwd!}/_build/nerves_env") do
        {:ok, file} ->
          build_env =
          case decode_term(file) do
            {:ok, term} -> term
            {:error, _} -> decode_elixir(file)
          end
          unless build_env["NERVES_TARGET"] == to_string(target) do
            cmd = clean_target(cmd)
          end
        _ -> cmd = clean_target(cmd)
      end
    else
      cmd = clean_target(cmd)
    end

    cmd = cmd <> """
    mix compile &&
    mix release &&
    sh #{rel2fw} rel/#{otp_name} _images/#{otp_name}-#{target}.fw
    """ |> remove_newlines


    result = Porcelain.shell(cmd, dir: system_path, env: env, out: stream)
    if File.dir?("#{File.cwd!}/_build") and result.status == 0 do
      File.write!("#{File.cwd!}/_build/nerves_env", encode_term(env))
    end

  end

  def burn(config, target, otp_name) do
    Bake.Shell.info "=> Burning firmware for target #{target}"
    {toolchain_path, system_path} = config_env(config, target)
    stream = IO.binstream(:standard_io, :line)
    env = [
      {"NERVES_APP", File.cwd!},
      {"NERVES_TOOLCHAIN", toolchain_path},
      {"NERVES_SYSTEM", system_path},
      {"MIX_ENV", System.get_env("MIX_ENV") || "dev"}
    ]
    fw = "_images/#{otp_name}-#{target}.fw"
    cmd = "fwup -a -i #{fw} -t complete"
    Porcelain.shell(cmd, env: env, out: stream)
  end

  defp remove_newlines(string) do
    string |> String.strip |> String.replace("\n", " ")
  end

  defp config_env(config, target) do
    target_atom =
    cond do
      is_atom(target) -> target
      true -> String.to_atom(target)
    end

    target_config = config
    |> Keyword.get(:target)
    |> Keyword.get(target_atom)
    recipe = target_config[:recipe]
    # TODO: Need to get locked version from the bakefile.lock

    # Check to ensure that the system is available in NERVES_HOME
    system_path = "#{systems_path}/#{recipe}"
    #Logger.debug "Path: #{inspect system_path}"
    if File.dir?(system_path) do
      #Logger.debug "System #{recipe} Found"
    else
      raise "System #{inspect recipe} not downloaded"
    end
    # Read the recipe config from the system
    {:ok, system_config} = "#{system_path}/recipe.exs"
    |> Bake.Config.Recipe.read!

    #Logger.debug "System Config: #{inspect system_config}"
    # Toolchain
    {username, toolchain_tuple, _toolchain_version} = system_config[:toolchain]
    host_platform = BakeUtils.host_platform
    host_arch = BakeUtils.host_arch
    toolchain_name = "#{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch}"

    toolchains = File.ls!(toolchains_path)
    toolchain_name = Enum.find(toolchains, &(String.starts_with?(&1, toolchain_name)))
    toolchain_path = "#{toolchains_path}/#{toolchain_name}"
    if File.dir?(toolchain_path) do
      #Logger.debug "Toolchain #{toolchain_tuple} Found"
    else
      raise "Toolchain #{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch} not downloaded"
    end
    {toolchain_path, system_path}
  end

  defp clean_target(cmd) do
    cmd <> """
    mix deps.clean --all &&
    mix deps.get &&
    mix deps.compile &&
    """
  end
end
