defmodule Bake.Daemon.Notification do
  import Bake.Utils.Brew, only: [package_installed?: 1]

  defstruct title: "Bakeware", subtitle: "", message: "", open: nil
  #TODO
  # • Notificaitons currently only support MacOS

  def present(%__MODULE__{} = notif) do
    if package_installed?("terminal-notifier"), do:
      System.cmd("terminal-notifier",
        ["-title", notif.title,
         "-subtitle", notif.subtitle,
         "-message", notif.message,
         "-open", notif.open]
      )
  end
end
