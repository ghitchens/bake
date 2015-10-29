defmodule Bake.Config.Utils do

  def get_config_and_stop_agent(agent) do
    config = Bake.Config.Agent.get(agent)
    Bake.Config.Agent.stop(agent)
    config
  end

  def merge(config1, config2) do
    Keyword.merge(config1, config2, fn _, app1, app2 ->
      Keyword.merge(app1, app2, &deep_merge/3)
    end)
  end

  def deep_merge(_key, value1, value2) do
    if Keyword.keyword?(value1) and Keyword.keyword?(value2) do
      Keyword.merge(value1, value2, &deep_merge/3)
    else
      value2
    end
  end
  
end
