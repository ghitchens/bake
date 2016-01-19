defmodule Bake.Daemon do

  def start do
    pid = :os.getpid
    File.write!(BakeUtils.daemon_pid, to_string(pid))
    Bake.Daemon.Server.start_link port: BakeUtils.daemon_port
    unless iex_running?, do: :timer.sleep(:infinity)
  end

  def stop do
    Bake.Daemon.Api.stop
  end

  def running? do
    case File.read(BakeUtils.daemon_pid) do
      {:ok, pid} ->
        :os.cmd(String.to_char_list("kill -0 #{pid}")) == []
      _ -> false
    end
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) && IEx.started?
  end
end
