defmodule Mix.Tasks.Bake.Deps.Get do
  use Mix.Task

  def run(args) do
    Mix.Task.run("deps.update", ["--all"])
  end

end
