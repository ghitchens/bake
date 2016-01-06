defmodule Bake.Api.Toolchain do
  alias Bake.Api
  @base_url "/toolchains"

  def get(%{tuple: tuple, username: username}) do
    Api.request(:get, Api.url(@base_url <> "/#{username}/#{tuple}"), [])
  end
end
