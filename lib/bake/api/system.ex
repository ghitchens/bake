defmodule Bake.Api.System do
  alias Bake.Api
  @base_url "/systems"

  # def compile(%{recipe: recipe}, auth) do
  #   Api.request(:post, Api.url(@base_url <> "/#{recipe}"), Api.auth(auth))
  # end

  def get(%{recipe: recipe}) do
    Api.request(:get, Api.url(@base_url <> "/#{recipe}"), [])
  end

  def toolchain(recipe) do
    Api.request(:get, Api.url(@base_url <> "/#{recipe}/toolchain"), [])
  end
end
