defmodule Bake do
  use Application

  require Logger

  def start do
    HTTPoison.start
    :ssh.start
    {:ok, _} = Application.ensure_all_started(:bake)
  end

  def start(_, _) do
    import Supervisor.Spec

    children = [
      worker(Bake.State, [])
    ]

    opts = [strategy: :one_for_one, name: Bake.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def version, do: unquote(Mix.Project.config[:version])
end
