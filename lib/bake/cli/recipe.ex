defmodule Bake.Cli.Recipe do
  @menu "recipe"
  @switches []

  use Bake.Cli.Menu
  require Logger

  def menu do
    """
      publish   - Publishes the changes to the recipe
      rollback  - Rollback the last published version of the recipe
    """
  end

  def main(args) do
    {_opts, cmd, _} = OptionParser.parse(args, switches: @switches)
    case cmd do
      ["publish"] -> publish
      ["rollback"] -> rollback
      _ -> invalid_cmd(cmd)
    end
  end

  def publish do
    recipe_config = System.cwd! <> "/config.exs"
    case Bake.Config.Recipe.read!(recipe_config) do
      {:ok, config} ->
        cli_config = BakeUtils.Cli.Config.read
        user = BakeUtils.local_user(cli_config)

        Bake.Shell.info("Publishing #{user}/#{config[:name]} v#{config[:version]}")
        if Bake.Shell.yes?("Proceed?") do
          tar = BakeUtils.Tar.pack(config)
          auth = BakeUtils.auth_info(cli_config)
          case Bake.Api.Recipe.publish(
            %{recipe_name: config[:name], user_name: user, content: tar},
            auth
          ) do
            {:ok, %{status_code: status_code, body: _body}} when status_code in 200..299 ->
              Bake.Shell.info("Published recipe #{user}/#{config[:name]} successfully")
            {_, response} ->
              Bake.Shell.error("Failed to publish recipe")
              Bake.Utils.print_response_result(response)
          end
        end
      {_, error} ->
        Bake.Shell.info "Error reading recipe config: #{inspect error}"
    end
  end

  def rollback do

  end

end
