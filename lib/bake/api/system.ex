defmodule Bake.Api.System do
  alias Bake.Api
  @base_url "/systems"

  # def compile(%{recipe: recipe}, auth) do
  #   Api.request(:post, Api.url(@base_url <> "/#{recipe}"), Api.auth(auth))
  # end

  def get(%{recipe: recipe, version: version}) do
    Api.request(:get, Api.url(@base_url <> "/#{recipe}/#{version}"), [])
  end

  def get(%{recipe: recipe}) do
    Api.request(:get, Api.url(@base_url <> "/#{recipe}"), [])
  end

end
