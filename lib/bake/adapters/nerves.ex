defmodule Bake.Adapters.Nerves do
  import Bake.Config.Global, only: [encode_term: 1, decode_term: 1, decode_elixir: 1]
  @behaviour Bake.Adapter

  @rebar_url "https://github.com/rebar/rebar/releases/download/2.6.1/rebar"
  @nerves_home System.get_env("NERVES_HOME") || "~/.nerves"

  require Logger
  defp nerves_home do
    if Process.whereis(Bake.State) do
      Bake.State.fetch!(:nerves_home)
    else
      Path.expand(System.get_env("NERVES_HOME") || @nerves_home)
    end
  end

  def systems_path, do: "#{nerves_home}/systems/" |> Path.expand
  def toolchains_path, do: "#{nerves_home}/toolchains/" |> Path.expand

  def firmware(bakefile_path, config, target, otp_name, opts \\ []) do
    otp_app_path = Path.dirname(bakefile_path)

    check_host_tools(:os.type)

    Bake.Shell.info "=> Building firmware for target #{target}"
    {toolchain_path, system_path} = config_env(bakefile_path, config, target)

    {:ok, system_config} = "#{system_path}/recipe.exs"
    |> Bake.Config.Recipe.read!

    {_, toolchain_tuple, _} = system_config[:toolchain]
    rel2fw_script = "#{system_path}/scripts/rel2fw.sh"
    stream = IO.binstream(:standard_io, :line)
    env = [
      {"NERVES_APP", otp_app_path},
      {"NERVES_TOOLCHAIN", toolchain_path},
      {"NERVES_SYSTEM", system_path},
      {"NERVES_TARGET", to_string(target)},
      {"REBAR_TARGET_ARCH", toolchain_tuple},
      {"MIX_ENV", System.get_env("MIX_ENV") || "dev"}
    ]

    result = Porcelain.shell(nerves_env(system_path), env: env, out: nil)

    if result.status != 0,
      do: Bake.Shell.error_exit "Nerves could not initialize the environment. Please fix the issue and try again"
    # The Nerves scripts require bash. The native shell could be sh, so
    # invoke bash for the rest of the script. Note the single double-quote
    # to keep the command to bash together.
    cmd = """
    mix local.hex --force &&
    mix local.rebar rebar #{@rebar_url} --force &&
    """

    #check for the env cache
    if File.dir?("#{otp_app_path}/_build") do
      # Load the env file
      case File.read("#{otp_app_path}/_build/nerves_env") do
        {:ok, file} ->
          build_env =
          case decode_term(file) do
            {:ok, term} -> term
            {:error, _} -> decode_elixir(file)
          end

          build_target = to_keyword_list(build_env)[:NERVES_TARGET]
          unless build_target == to_string(target) do
            cmd = clean_target(cmd)
          end
        _ -> cmd = clean_target(cmd)
      end
    else
      cmd = clean_target(cmd)
    end
    verbosity = Map.get(opts, :verbosity, "normal")
    cmd = cmd <> """
    mix compile &&
    mix release.clean &&
    mix release --verbosity=#{verbosity}
    """ |> remove_newlines

    IO.puts "Cmd: #{inspect cmd}"
    porcelain_opts = [dir: otp_app_path, env: env, in: stream, async_in: true, out: stream]
    compile_result =
      nerves_env(cmd, system_path)
      |> Porcelain.shell(porcelain_opts)
    if File.dir?("#{otp_app_path}/_build") and result.status == 0 do
      rel2fw_result =
        rel2fw(rel2fw_script, otp_app_path, otp_name, target)
        |> nerves_env(system_path)
        |> Porcelain.shell(porcelain_opts)
      case rel2fw_result do
        %{status: 0} ->
          File.write!("#{otp_app_path}/_build/nerves_env", encode_term(env))
        _ ->
          rel2fw_v1(rel2fw_script, otp_app_path, otp_name, target)
          |> nerves_env(system_path)
          |> Porcelain.shell(porcelain_opts)
      end

    else
      Bake.Shell.info "Release Failed"
    end
  end

  def clean do
    Bake.Shell.info "=> Cleaning project"
    cmd = """
    mix release.clean &&
    mix clean &&
    rm -rf _images/*.fw
    """ |> remove_newlines
    stream = IO.binstream(:standard_io, :line)
    Bake.Shell.info "==> Removing firmware images"
    Porcelain.shell(cmd, out: stream)
  end

  def burn(bakefile_path, config, target, otp_name, args) do
    Bake.Shell.info "=> Burning firmware #{otp_name}-#{target}.fw"
    {toolchain_path, system_path} = config_env(bakefile_path, config, target)
    stream = IO.binstream(:standard_io, :line)
    env = [
      {"NERVES_APP", File.cwd!},
      {"NERVES_TOOLCHAIN", toolchain_path},
      {"NERVES_SYSTEM", system_path},
      {"MIX_ENV", System.get_env("MIX_ENV") || "dev"}
    ]
    fw = "_images/#{otp_name}-#{target}.fw"
    cmd = "fwup -a -i #{fw} -t complete #{args}"

    {env, cmd} =
      case Bake.Utils.host_platform do
        <<"linux", _ :: binary >> ->
          sudo_askpass = System.get_env("SUDO_ASKPASS") || "/usr/bin/ssh-askpass"
          env = [{"SUDO_ASKPASS", sudo_askpass} | env]
          {env, "sudo " <> cmd}
        _ -> {env, cmd}
      end
    Porcelain.shell(cmd, env: env, in: stream, async_in: true, out: stream)
  end

  defp remove_newlines(string) do
    string |> String.strip |> String.replace("\n", " ")
  end

  defp config_env(bakefile_path, config, target) do
    target_atom =
    cond do
      is_atom(target) -> target
      true -> String.to_atom(target)
    end

    target_config = config
    |> Keyword.get(:target)
    |> Keyword.get(target_atom)

    lock_path = bakefile_path
    |> Path.dirname
    lock_path = lock_path <> "/Bakefile.lock"
    system_path = ""
    system_version = ""
    if File.exists?(lock_path) do
      # The exists. Check to see if it contains a lock for our target
      lock_file = Bake.Config.Lock.read(lock_path)
      lock_targets = lock_file[:targets]
      target =
      if is_binary(target) do
        String.to_atom(target)
      else
        target
      end
      case Keyword.get(lock_targets, target) do
        nil ->
          Bake.Shell.error_exit "You must run bake system get for target #{target} before bake firmware"
        [{recipe, version}] ->
          system_path = "#{systems_path}/#{recipe}-#{version}"
          recipe = recipe
          system_version = version
          unless File.dir?(system_path) do
            Bake.Shell.error_exit "System #{inspect recipe} not downloaded"
          end
      end
    else
      Bake.Shell.error_exit "You must run bake system get before bake firmware"
    end
    {recipe, _} = target_config[:recipe]
    Bake.Shell.info "==> Using System: #{recipe}-#{system_version}"

    # Read the recipe config from the system
    {:ok, system_config} = "#{system_path}/recipe.exs"
    |> Bake.Config.Recipe.read!

    #Logger.debug "System Config: #{inspect system_config}"
    # Toolchain
    {username, toolchain_tuple, toolchain_version} = system_config[:toolchain]
    host_platform = Bake.Utils.host_platform
    host_arch = Bake.Utils.host_arch
    toolchain_path = "#{toolchains_path}/#{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch}-v#{toolchain_version}"
    Bake.Shell.info "==> Using Toolchain: #{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch}-v#{toolchain_version}"
    # toolchains = File.ls!(toolchains_path)
    # toolchain_name = Enum.find(toolchains, &(String.starts_with?(&1, toolchain_name)))
    # toolchain_path = "#{toolchains_path}/#{toolchain_name}"
    if File.dir?(toolchain_path) do
      #Logger.debug "Toolchain #{toolchain_tuple} Found"
    else
      raise "Toolchain #{username}-#{toolchain_tuple}-#{host_platform}-#{host_arch}-v#{toolchain_version} not downloaded"
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

  defp to_keyword_list(build_env) do
    Enum.map(build_env, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp rel2fw(script, otp_app_path, otp_app, target) do
    """
    bash #{script} -f _images/#{otp_app}-#{target}.fw rel/#{otp_app}
    """ |> remove_newlines
  end

  defp rel2fw_v1(script, _otp_app_path, otp_app, target) do
    Bake.Shell.warn """
    Using rel2fw protocol v1, the following services are unavailable:
    rootfs-additions, custom fwup.conf
    """

    """
    bash #{script} rel/#{otp_app} _images/#{otp_app}-#{target}.fw
    """ |> remove_newlines
  end

  defp nerves_env(script \\ "", system_path) do
    cmd = """
    bash -c "
    source #{system_path}/nerves-env.sh || exit 1
    #{script} "
    """
  end

  defp check_host_tools({_, :darwin}) do
    unless Bake.Utils.installed?("gstat") do
      Bake.Shell.error_exit """
      merge-squashfs: ERROR: Please install gstat first
      For example:
        brew install coreutils
      """
    end
  end
  defp check_host_tools({_, _}), do: nil
end
