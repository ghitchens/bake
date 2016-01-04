defmodule Bake.Api.Update do
  alias Bake.Api
  @base_url "/update"

  def get do
    Api.request(:get, Api.url(@base_url), [])
  end

end
