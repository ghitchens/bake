defmodule Bake.Cli do
  use Bake.Cli.Menu
  alias Bake.Cli
  require Logger

  @switches []

  def menu do
    """
      bake    - Bake firmware for a --target or --all targets
      user    - User management commands
      system  - Target system options
      burn    - Install language helper functions
    """
  end

  def main(args) do
    Bake.start
    case args do
      ["user" | cmd] -> Cli.User.main(cmd)
      ["system" | cmd] -> Cli.System.main(cmd)
      ["burn" | cmd] -> Cli.Burn.main(cmd)
      _ -> bake(args)
    end
  end

  def bake(args) do
    Cli.Bake.main(args)
  end
end
