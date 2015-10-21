defmodule Bake.Cli do
  use Bake.Cli.Menu
  alias Bake.Cli
  require Logger

  @switches []

  def menu do
    """
      bake      - Bake firmware for a --target or --all targets
      user      - User management commands
      daemon    - Control the local bake daemon
      toolchain - Toolchain options
      system    - Target system options
      firmware  - Target Firmware options
      burn      - Install language helper functions
    """
  end

  def main(args) do
    Bake.start
    case args do
      ["user" | cmd] -> Cli.User.main(cmd)
      ["system" | cmd] -> Cli.System.main(cmd)
      ["toolchain" | cmd] -> Cli.Toolchain.main(cmd)
      ["burn" | cmd] -> Cli.Burn.main(cmd)
      ["daemon" | cmd] -> Cli.Daemon.main(cmd)
      _ -> bake(args)
    end
  end

  def bake(args) do
    Cli.Bake.main(args)
  end
end
