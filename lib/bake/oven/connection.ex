defmodule Bake.Oven.Connection do
  require Logger

  def start do
    {:ok, conn} = :ssh.connect('127.0.0.1', 2200, [ {:user,'vagrant'}, {:silently_accept_hosts, true}, {:password, 'vagrant'} ], 5000)
    str = SSHEx.stream conn, 'cd /opt/nerves-sdk && ls'

    Stream.each(str, fn(x)->
      case x do
        {:stdout,row}    -> Logger.debug "[out] #{inspect row}"
        {:stderr,row}    -> Logger.error "[error] #{inspect row}"
        {:status,status} -> Logger.debug "[exit] #{inspect status}"
      end
    end)

    Logger.debug "Here"
  end
end
