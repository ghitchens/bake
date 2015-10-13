defmodule Bake.Oven.Message do
  def parse({result, 0}, :status) do
    [_, _, _, status | _] = String.split(result, "\n")
      |> Enum.map(&String.split(&1, ","))
      |> Enum.find(fn([_, _, type | _])-> type == "state" end)
    String.to_atom(status)
  end

  def parse({result, 0}, :"ssh-config") do
    String.split(result, "\n")
      |> Enum.map(&String.strip/1)
      |> Enum.map(&String.downcase/1)
      |> Enum.map(&String.split(&1, " "))
      |> Enum.reduce([], fn(list, acc) ->
        case list do
          [""] -> acc
          [k, v] -> Keyword.put(acc, String.to_atom(k), v)
        end
      end)
  end

  def parse({result, _}, _), do: result
end
