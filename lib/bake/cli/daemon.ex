defmodule Bake.Cli.Daemon do
  @menu "daemon"
  @switches [target: :string, all: :boolean, foreground: :boolean]

  use Bake.Cli.Menu

  def menu do
    """
      start   - Starts the bake daemon
      stop    - Stops the bake daemon
      running - Check if the local bake daemon is running
    """
  end

  def main(args) do
    Bake.start
    {opts, cmd, _} = OptionParser.parse(args, switches: @switches)
    case cmd do
      ["start"] -> start(opts)
      ["stop"] -> stop
      ["running"] -> running
      _ -> invalid_cmd(cmd)
    end
  end

  def start(foreground: true) do
    IO.puts "Foreground"
    Bake.Daemon.start
  end
  def start(_) do
    if Bake.Utils.daemon_running? do
      Bake.Shell.info info_bake_running
    else
      result = Port.open({:spawn, "bake daemon start --foreground"}, [])

      Bake.Shell.info "=> bake daemon started"
    end
  end

  def stop do
    if Bake.Utils.daemon_running? do
      Bake.Shell.info "=> Stopping #{info_bake_running}"
      Bake.Daemon.stop
    else
      Bake.Shell.info "=> bake daemon is not running"
    end

  end

  def running do
    if Bake.Utils.daemon_running? do
      Bake.Shell.info "=> #{info_bake_running}"
    else
      Bake.Shell.info "=> bake daemon is not running"
    end
  end

  defp info_bake_running, do: "bake daemon running on port #{inspect Bake.Utils.daemon_port}"

end
