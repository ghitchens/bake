defmodule Bake.Api do
  require Logger

  def request(method, url, headers, body \\ "") do
    default_headers = [
      "Content-Type": "application/json",
      "User-Agent": user_agent,
      "x-bake-host-arch": BakeUtils.host_arch
    ]
    headers = Keyword.merge(default_headers, headers)
    HTTPoison.request(
      method,
      url,
      Poison.encode!(body),
      headers
    )
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
end
