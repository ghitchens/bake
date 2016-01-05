defmodule Bake.Adapter.Assemble do
  use Behaviour

  defcallback firmware(config :: Bake.Config.t, target :: Atom.t, otp_name :: String.t) :: nil
end
