defmodule Bake.Api.User do
  alias Bake.Api
  @base_url "/users"

  def create(params) do
    Api.request(:post, Api.url(@base_url), [], %{user: params})
  end

  def get(username, auth) do
    Api.request(:get, Api.url(@base_url <> "/#{username}"), Api.auth(auth))
  end
end
