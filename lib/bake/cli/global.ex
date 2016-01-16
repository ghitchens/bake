defmodule Bake.Cli.Global do
  @menu "global"
  @switches []

  use Bake.Cli.Menu
  require Logger

  defp menu do
    """
      set variable value  - Set a global variable
      get variable        - Show a global variable
      clear variable      - Clear a global variable
    """
  end

  def main(args) do
    {_opts, cmd, _} = OptionParser.parse(args, switches: @switches)
    case cmd do
      ["set" | [variable | [value | _]]] -> set(variable, value)
      ["get" | [variable | _]] -> get(variable)
      ["clear" | [variable | _]] -> clear(variable)
      _ -> invalid_cmd(cmd)
    end
  end

  def set(variable, value) do
    Bake.Shell.info "=> Setting global variable #{variable} to #{value}"
    BakeUtils.Cli.Config.update([{String.to_atom(variable), value}])
  end

  def get(variable) do
    case BakeUtils.Cli.Config.read[String.to_atom(variable)] do
      nil -> Bake.Shell.info "=> Global variable #{variable} is not set"
      value -> Bake.Shell.info "=> Global variable #{variable}: #{value}"
    end
  end

  def clear(variable) do
    case get(variable) do
      nil -> Bake.Shell.info "=> Global variable #{variable} is not set"
      _ ->
        BakeUtils.Cli.Config.read
        |> Keyword.delete(String.to_atom(variable))
        |> BakeUtils.Cli.Config.write
    end
  end

end
