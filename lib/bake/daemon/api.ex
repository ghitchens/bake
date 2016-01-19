defmodule Bake.Daemon.Api do
  @sock_opts [{:active, true}, :binary, {:packet, :raw}, {:delay_send, false}]

  def connect do
    :gen_tcp.connect('127.0.0.1', BakeUtils.daemon_port, @sock_opts, 5000)
  end

  def stop do
    case connect() do
      {:ok, client} ->
        :gen_tcp.send(client, "/q\n")
        :ok
      {_, error} -> {:error, error}
    end
  end
end
