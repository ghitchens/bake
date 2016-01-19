defmodule Bake.Daemon.Server do
  use GenServer
  alias Bake.Daemon.Client
  require Logger

  @accept_timeout 1000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Bake.Daemon.Server)
  end

  def join_channel do
    GenServer.cast(__MODULE__, :join_channel)
  end

  def leave_channel do
    GenServer.cast(__MODULE__, :leave_channel)
  end

  def init([port: port]) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.debug "Started Server on port #{inspect port}"

    send(self, :accept)
    {:ok, %{
      socket: socket,
      channel: nil
    }}
  end

  def handle_info(:accept, %{socket: socket} = s) do
    #Logger.debug "Waiting for Client"
    case :gen_tcp.accept(socket, @accept_timeout) do
      {:ok, client} ->
        {:ok, pid} = Client.start_link([socket: client])
        Process.unlink(pid)
      _ -> nil
    end
    send(self, :accept)
    {:noreply, s}
  end

  def handle_cast(:join_channel, state) do
    config = Bake.Config.Global.read
    username = Bake.Utils.local_user(config)
    BakeDaemon.Channel.Socket.start_link
    {:ok, channel} = Phoenix.Channel.Client.channel(BakeDaemon.Channel.User, socket: BakeDaemon.Channel.Socket, topic: "user:#{username}")
    auth = Bake.Utils.auth_info(config)
    BakeDaemon.Channel.User.join(channel, %{key: auth[:key]})
    {:noreply, %{state | channel: channel}}
  end

  def handle_cast(:leave_channel, state) do
    BakeDaemon.Channel.User.leave(state.channel)
    {:noreply, %{state | channel: nil}}
  end
end
