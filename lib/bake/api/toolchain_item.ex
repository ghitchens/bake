defmodule Bake.Api.ToolchainItem do
  alias Bake.Api
  @base_url "/toolchain_items"

  def fetch(platform, type) do
    Api.request(:get, Api.url(@base_url <> "/#{platform}/#{type}"), [])
  end
end
