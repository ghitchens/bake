defmodule Bake.Compiler.System do
  require Logger
  alias Bake.Utils

  def compile(config) do
    Logger.debug "System Compile Config: #{inspect config}"
    {_, target} =
      config[:target]
      |> List.first
    bake_config = BakeUtils.Cli.Config.read
    auth = BakeUtils.auth_info(bake_config)
    result = Bake.Api.System.get(
      %{recipe: target[:recipe]},
      auth
    )
    case result do
      {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
        body = Poison.decode! body, keys: :atoms
        parse_status(body)
      {_, response} ->
        Bake.Shell.error("Failed to call for system compile")
        Bake.Utils.print_response_result(response)
    end
  end

  def parse_status(%{status: "queued"}) do
    Logger.debug "Status Queued"
  end

  def parse_status(%{status: "cached", source: source}) do
    Logger.debug "Status Cached: #{inspect source}"
  end
end
