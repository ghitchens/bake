defmodule Bake.Adapters.Nerves.System do

  def get(target_config) do
    target_config[:target]
      |> Enum.reduce(HashSet.new, fn({k, config}, acc) ->
        case Bake.Api.System.toolchain(config[:recipe]) do
          {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
            items = Poison.decode!(body)
              |> Map.get("data")
            Enum.reduce(items, acc, &(HashSet.put(&2, &1)))
          {_, response} ->
            Bake.Shell.error("Failed to get toolchain for #{k}")
            Bake.Utils.print_response_result(response)
            acc
        end
      end)
      |> HashSet.to_list
      |> request
  end

  def request(system) do
    
  end

end
