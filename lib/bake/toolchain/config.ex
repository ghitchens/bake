defmodule Bake.Toolchain.Config do

  require Logger

  import Bake.Config.Utils

  defmacro __using__(_opts) do
    quote do
      import Bake.Toolchain.Config, only: [platform: 1, target: 2]
      {:ok, agent} = Bake.Config.Agent.start_link
      var!(config_agent, Bake.Config) = agent
    end
  end

  defmacro platform(name) do
    quote do
      Bake.Config.Agent.merge var!(config_agent, Bake.Config),
         [{:platform, unquote(name)}]
    end
  end

  defmacro target(name, opts) do
    quote do
      Bake.Config.Agent.merge var!(config_agent, Bake.Config),
         [{:target, [{unquote(name), unquote(opts)}]}]
    end
  end

  def read!(file) do
    try do
      {config, binding} = Code.eval_file(file)
      config = case List.keyfind(binding, {:config_agent, Bake.Config}, 0) do
        {_, agent} -> get_config_and_stop_agent(agent)
        nil        -> config
      end
      {:ok, config}
    rescue
      e -> {:error, e}
    end
  end

  def filter_target(config, {:all}), do: config
  def filter_target(config, target) do
    target_config = (config[:target] || [])
      |> Keyword.take([String.to_atom(target)])
    case target_config do
      [] -> []
      target_config ->
        config
          |> Keyword.delete(:target)
          |> Keyword.merge([target: target_config])
    end
  end



end
