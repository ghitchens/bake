defmodule Bake.Adapter.Assemble do
  use Behaviour

  defcallback firmware(config :: Bake.Config.t, target :: Atom.t, name :: String.t) :: nil
end
