defmodule Bake.Cli.Menu do
  use Behaviour

  defcallback menu(cmd :: binary)

  defmacro __using__(_) do
    quote do
      import Bake.Cli.Menu

      def invalid_cmd,      do: Bake.Shell.info menu
      def invalid_cmd(""),  do: Bake.Shell.info menu
      def invalid_cmd(cmd) do
        mod = Atom.to_string(__MODULE__)
          |> String.split(".")
          |> List.last
          |> String.downcase
        Bake.Shell.info "Invalid #{mod} command - #{cmd}"
        Bake.Shell.info menu
      end
    end
  end
end
