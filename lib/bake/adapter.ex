defmodule Bake.Adapter do
  use Behaviour

  defcallback systems_path() :: String.t
  defcallback toolchains_path() :: String.t

  defcallback firmware(config :: Bake.Config.t, target :: Atom.t, otp_name :: String.t) :: nil
  defcallback burn(config :: Bake.Config.t, target :: Atom.t, otp_name :: String.t) :: nil
  defcallback clean() :: nil

end
