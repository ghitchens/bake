defmodule Bake.Api.Recipe do
  alias Bake.Api
  @base_url "/recipes"
  require Logger
  # def compile(%{recipe: recipe}, auth) do
  #   Api.request(:post, Api.url(@base_url <> "/#{recipe}"), Api.auth(auth))
  # end

  def get(%{recipe: recipe}, auth) do
    Api.request(:get, Api.url(@base_url <> "/#{recipe}"), Api.auth(auth))
  end

  def publish(%{recipe_name: recipe, user_name: user, content: content}, auth) do
    Api.request(:post, Api.url(@base_url <> "/#{user}/#{recipe}"), Api.auth(auth), content)
  end
end
