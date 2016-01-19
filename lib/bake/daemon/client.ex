defmodule Bake.Daemon.Client do
  use GenServer
  alias Bake.Daemon.Message
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([socket: socket]) do
    send(self, :recv)
    {:ok, %{socket: socket}}
  end

  def handle_info(:recv, %{socket: socket} = s) do
    cmd = socket
      |> read_line

    case cmd do
      {:ok, cmd} ->
        Message.parse(cmd)
        send(self, :recv)
        {:noreply, s}
      _ -> {:stop, :ok, s}
    end
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        data = data |> String.strip
        {:ok, data}
      {_, error} -> {:error, error}
    end
  end
end
