defmodule Bake.Api.Key do
  alias Bake.Api

  @base_url "/keys"

  def create(%{username: username, password: password, machine_name: machine_name}) do
    Api.request(
      :post,
      Api.url(@base_url),
      Api.auth(username: username, password: password),
      %{key: %{machine_name: machine_name}}
    )
  end
end
