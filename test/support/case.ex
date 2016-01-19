defmodule BakeTest.Case do
  use ExUnit.CaseTemplate

  require Logger

  using do
    quote do
      import unquote(__MODULE__)
      alias BakeTest.Case
    end
	end

  def tmp_path do
    Path.expand("../../tmp", __DIR__)
  end

  def tmp_path(extension) do
    Path.join(tmp_path, extension)
  end

  setup do
    Bake.State.put(:bake_home, tmp_path("bake_home"))
    Bake.State.put(:nerves_home, tmp_path("nerves_home"))
    Mix.shell(Mix.Shell.Process)
    Mix.Task.clear
    Mix.Shell.Process.flush
    Mix.ProjectStack.clear_cache
    Mix.ProjectStack.clear_stack
    :ok
  end
end
