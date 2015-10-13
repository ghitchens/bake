defmodule Bake.Config do

  require Logger

  defmacro __using__(_opts) do
    quote do
      import Bake.Config, only: [platform: 1, target: 2]
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
      config
    rescue
      e -> nil
    end
  end

  defp get_config_and_stop_agent(agent) do
    config = Bake.Config.Agent.get(agent)
    Bake.Config.Agent.stop(agent)
    config
  end

  def merge(config1, config2) do
    Keyword.merge(config1, config2, fn _, app1, app2 ->
      Keyword.merge(app1, app2, &deep_merge/3)
    end)
  end

  defp deep_merge(_key, value1, value2) do
    if Keyword.keyword?(value1) and Keyword.keyword?(value2) do
      Keyword.merge(value1, value2, &deep_merge/3)
    else
      value2
    end
  end
end
