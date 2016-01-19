defmodule Bake.Daemon.Channel.User do
  use Phoenix.Channel.Client
  require Logger

  def handle_in("task:status", %{"message" => message}, state) do
    Logger.debug "Handle Status"
    %Bake.Daemon.Notification{message: message} |> Bake.Daemon.Notification.present
    {:noreply, state}
  end

  def handle_in("task:log", %{"message" => message}, state) do
    Logger.debug "[oven]: #{message}"
    #%BakeDaemon.Notification{message: message} |> BakeDaemon.Notification.present
    {:noreply, state}
  end

  def handle_in(event, payload, state) do
    Logger.debug "Handle In: #{inspect event}\n#{inspect payload}"
    {:noreply, state}
  end

  def handle_reply(payload, state) do
    Logger.debug "Handle Reply: #{inspect payload}"
    {:noreply, state}
  end

  def handle_close(_payload, state) do
    {:noreply, state}
  end
end
