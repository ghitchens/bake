defmodule Bake.Compiler do
  @bakefile "Bakefile"

  def compile(target, bakefile) do
    # TODO
    # Determine information about the lang compiling for
    bake_config = Bake.Config.read!(bakefile)

  end
end
