defmodule BakeTest.Bakeware do

  require Logger

  def init do
    cmd("mix", ["ecto.drop", "-r", "Bakeware.Repo", "--quiet"])
    cmd("mix", ["ecto.create", "-r", "Bakeware.Repo", "--quiet"])
    cmd("mix", ["ecto.migrate", "-r", "Bakeware.Repo"])
    cmd("mix", ["run", "priv/repo/seeds.exs", "--quiet"])
  end

  def start do
    Logger.debug "Start Bakeware"
    bake_version = Bake.Utils.cli_version |> String.to_char_list
    mix = :os.find_executable('mix')
    port = Port.open({:spawn_executable, mix}, [
                     :exit_status,
                     :use_stdio,
                     :stderr_to_stdout,
                     :binary,
                     :hide,
                     env: [{'MIX_ENV', 'bake'},{'BAKE_VERSION', bake_version}],
                     cd: bakeware_dir(),
                     args: ["phoenix.server"]])

    fun = fn fun ->
      receive do
        {^port, {:data, data}} ->
          IO.write(data)
          fun.(fun)
        {^port, {:exit_status, status}} ->
          IO.puts "Bakeware quit with status #{status}"
          System.exit(status)
      end
    end

    spawn(fn -> fun.(fun) end)

    wait_on_start()
  end

  defp wait_on_start do
    case :httpc.request(:get, {'http://localhost:4040', []}, [], []) do
      {:ok, _} ->
        :ok
      {:error, _} ->
        :timer.sleep(10)
        wait_on_start()
    end
  end

  defp check_hexweb do
    dir = bakeware_dir()

    unless File.exists?(dir) do
      IO.puts "Unable to find #{dir}, make sure to clone the bakeware repository " <>
              "into it to run integration tests"
      System.exit(1)
    end
  end

  defp cmd(command, args) do
    opts = [
        stderr_to_stdout: true,
        into: IO.stream(:stdio, :line),
        env: [{"MIX_ENV", "bake"}],
        cd: bakeware_dir()]

    0 = System.cmd(command, args, opts) |> elem(1)
  end

  defp bakeware_dir do
    System.get_env("BAKEWARE_DIR") || "../bakeware"
  end

end
