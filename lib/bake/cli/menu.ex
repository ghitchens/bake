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
      def target(bakefile, "all") do
        targets = Enum.reduce(bakefile[:target], [], fn({target, _}, acc) ->  [target | acc] end)
        |> Enum.join(", ")
        Bake.Shell.info "==> Performing action on all targets: #{targets}"
        :all
      end
      def target(bakefile, nil) do
        default_target(bakefile, Keyword.get(bakefile, :default_target))
      end
      def target(_, target), do: target

      def default_target(bakefile, nil) do
        case BakeUtils.Cli.Config.read[:default_target] do
          target when target in ["", nil] ->
            error = """
            No target specified
            The project declares the following targets:\n
            """
            error = Enum.reduce(bakefile[:target], error, fn({target, _}, error) -> error <> "#{target}\n" end)
            error = error <> """

            You can re run your command and pass --target rpi2

            or set a default_target in the Bakefile for the project
            default_target: rpi2

            or set one of these targets as your global default
            bake global set default_target rpi2
            """

            Bake.Shell.error_exit error
          target ->
            Bake.Shell.info "==> Using global default target: #{target}"
            target
        end
      end
      def default_target(_bakefile, target) do
        Bake.Shell.info "==> Using project default target: #{target}"
        target
      end

      def all_warn(all: true) do
        Bake.Shell.info """
        (Bake Warning) If you want to perform an action on all targets use
        bake #{@menu} command --target all
        """
      end
      def all_warn(_), do: nil

      def adapter(platform) do
        platform = platform
          |> to_string
          |> String.capitalize
        Module.concat("Elixir.Bake.Adapters", platform)
      end

    end
  end
end
