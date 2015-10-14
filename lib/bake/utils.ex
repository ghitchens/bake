defmodule Bake.Utils do

  require Logger

  def print_response_result(%{body: body, status_code: status_code}) do
    case Poison.decode(body) do
      {:ok, %{"errors" => errors}} ->
        pretty_errors(errors)
      {:error, error} ->
        Bake.Shell.info pretty_http_code(status_code)
    end
  end

  defp pretty_errors(errors, depth \\ 0) do
    Enum.each(errors, fn
      {key, map} when is_map(map) ->
        Bake.Shell.info indent(depth) <> key <> ":"
        pretty_errors(map, depth + 1)
      {key, list} when is_list(list) ->
        Enum.each(list, fn(value) -> Bake.Shell.info indent(depth) <> key <> ": " <> value end)
      {key, value} ->
        Bake.Shell.info indent(depth) <> key <> ": " <> value
    end)
  end

  defp indent(0), do: "  "
  defp indent(depth), do: "  " <> indent(depth - 1)

  defp pretty_http_code(401), do: "Authentication failed (401)"
  defp pretty_http_code(403), do: "Forbidden (403)"
  defp pretty_http_code(404), do: "Entity not found (404)"
  defp pretty_http_code(422), do: "Validation failed (422)"
  defp pretty_http_code(code), do: "HTTP status code: #{code}"

  def generate_key(username, password) do
    Bake.Shell.info("Generating API key...")
    {:ok, machine_name} = :inet.gethostname()
    machine_name = List.to_string(machine_name)

    params = %{
      machine_name: machine_name,
      username: username,
      password: password
    }
    case Bake.Api.Key.create(params) do
      {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
        Bake.Shell.info("API key created")
        key = Poison.decode!(body)
          |> Map.get("data")
          |> Map.get("key")
        Bake.Cli.Config.update(username: username, key: key)
        :ok
      {_, response} ->
        Bake.Shell.error("API key generation failed")
        Bake.Utils.print_response_result(response)
        :error
    end
  end

  def auth_info(config \\ Bake.Config.read) do
    if key = config[:key] do
      [key: key]
    else
      Mix.raise "No authorized user found. Run 'mix bake.user auth'"
    end
  end

  # Password prompt that hides input by every 1ms
  # clearing the line with stderr
  # Thanks Hex
  def password_get(prompt, clean?) do
    if clean? do
      pid = spawn_link fn -> loop(prompt) end
      ref = make_ref()
    end

    value = IO.gets(prompt <> " ")

    if clean? do
      send pid, {:done, self(), ref}
      receive do: ({:done, ^pid, ^ref}  -> :ok)
    end

    value
  end

  defp loop(prompt) do
    receive do
      {:done, parent, ref} ->
        send parent, {:done, self, ref}
        IO.write :standard_error, "\e[2K\r"
    after
      1 ->
        IO.write :standard_error, "\e[2K\r#{prompt} "
        loop(prompt)
    end
  end

end
