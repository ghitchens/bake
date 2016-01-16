defmodule Bake.Cli.Daemon do
  @menu "daemon"
  @switches [target: :string, all: :boolean]

  use Bake.Cli.Menu


  defp menu do
    """
      start   - Starts the bake daemon
      stop    - Stops the bake daemon
      running - Check if the local bake daemon is running
    """
  end

  def main(args) do
    Bake.start
    {_opts, cmd, _} = OptionParser.parse(args, switches: @switches)
    case cmd do
      ["start"] -> start
      ["stop"] -> stop
      ["running"] -> running
      _ -> invalid_cmd(cmd)
    end
  end

  def start do
    {ret, 0} = System.cmd("bake_d", ["running"])
    if String.contains?(ret, "running on") do
      Bake.Shell.info ret
    else
      Port.open({:spawn, "bake_d"}, [])
      Bake.Shell.info "bake daemon started"
    end
  end

  def stop do
    {ret, 0} = System.cmd("bake_d", ["stop"])
    Bake.Shell.info ret
  end

  def running do
    {ret, 0} = System.cmd("bake_d", ["running"])
    Bake.Shell.info ret
  end

end
