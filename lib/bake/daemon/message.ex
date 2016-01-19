defmodule Bake.Daemon.Message do
  require Logger

  def parse("/q") do
    File.rm(Bake.Utils.daemon_pid)
    :erlang.halt
  end

  def parse(<<"/notification ", tail :: binary>>) do
    %Bake.Daemon.Notification{message: tail} |> Bake.Daemon.Notification.present
  end

  def parse("/join_channel") do
    Bake.Daemon.Server.join_channel
  end

  def parse(cmd), do: Logger.debug "Unexpected Command: #{inspect cmd}"

end
