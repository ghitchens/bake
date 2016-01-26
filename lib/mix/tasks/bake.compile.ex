defmodule Mix.Tasks.Bake.Firmware do
  use Mix.Task

  def run(args) do
    Bake.Shell.info("=> Compiling Elixir in Nerves Environment")
    Mix.Task.run("compile", [])
  end

end
