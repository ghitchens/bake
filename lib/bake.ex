defmodule Bake do
  def start do
    HTTPoison.start
    :ssh.start
    {:ok, _} = Application.ensure_all_started(:bake)
  end

  def version, do: unquote(Mix.Project.config[:version])
end
