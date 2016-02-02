defmodule Bake.Api do
  require Logger

  @timeout 60_000

  def request(method, url, headers, body \\ "") do
    default_headers = [
      "User-Agent": user_agent,
      "x-bake-host-arch": Bake.Utils.host_arch,
      "x-bake-host-platform": Bake.Utils.host_platform,
      "x-bake-version": Bake.Utils.cli_version
    ]
    headers = Keyword.merge(default_headers, headers)
    {body, headers} = encoding(body, headers)

    HTTPoison.request(
      method,
      url,
      body,
      headers,
      timeout: timeout,
      recv_timeout: timeout,
      follow_redirect: true
    ) |> response
  end

  def response({:error, _} = response), do: response
  def response({:ok, %{headers: headers}} = response) do
    update = Enum.find(headers, fn({header, _}) -> String.downcase(header) == "x-bake-version" end)
    if update != nil do
      {_, version} = update
      Bake.Shell.info "A new version of Bake is available: #{version}"
      Bake.Shell.info "You can update by running: bake update"
    end
    response
  end

  def encoding("", headers), do: {"", headers}
  def encoding(body, headers) do
    try do
      case Poison.encode(body) do
        {:ok, payload} ->
          {payload, Keyword.merge(headers, ["Content-Type": "application/json"])}
        _ ->
          {body, headers}
      end
    rescue
      _e -> {body, headers}
    end
  end

  def url(path) do
    Application.get_env(:bake, :api_host) <> path
  end

  def auth(key: secret) do
    [{"authorization", secret}]
  end

  def auth(info) do
    base64 = Base.encode64(info[:username] <> ":" <> info[:password])
    ["authorization": "Basic #{base64}"]
  end

  def user_agent do
    "Bake/#{Bake.version} (Elixir/#{System.version})"
  end

  def timeout do
    @timeout
  end
end
