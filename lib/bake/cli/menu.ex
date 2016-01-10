defmodule Bake.Cli.Menu do
  use Behaviour

  defcallback menu(cmd :: binary)

  defmacro __using__(_) do
    quote do
      import Bake.Cli.Menu
      require Logger
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

      def bakefile(nil, target), do: bakefile(System.cwd! <> "/Bakefile", target)
      def bakefile(bakefile, target) do
        case Bake.Config.read!(bakefile) do
          {:ok, config} ->
            target = target(config, target)

            target_config =
            case Bake.Config.filter_target(config, target) do
              [] ->
                Bake.Shell.error_exit "Bakefile does not contain definition for target #{target}"
              target_config -> target_config
            end
            {bakefile, target_config, target}
          {:error, e} ->
            Bake.Shell.error_exit "Failed to parse bakefile: #{inspect e}"
        end
      end

      # Check the config for a default target
      def target(bakefile, "all"), do: :all
      def target(bakefile, nil) do
        case Keyword.get(bakefile, :default_target) do
          nil -> Bake.Shell.error_exit "You must provide a target by passing --target {target name}"
          target -> target
        end
      end
      def target(_, target), do: target

      def adapter(platform) do
        platform = platform
          |> to_string
          |> String.capitalize
        Module.concat("Elixir.Bake.Adapters", platform)
      end

    end
  end
end
