defmodule Bake.Config do
  use Bake.Config.Utils

  require Logger

  defmacro __using__(_opts) do
    quote do
      import Bake.Config, only: [platform: 1, default_target: 1, target: 2]
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

  defmacro default_target(name) do
    quote do
      Bake.Config.Agent.merge var!(config_agent, Bake.Config),
         [{:default_target, unquote(name)}]
    end
  end
  defmacro target(name, opts) do
    quote do
      Bake.Config.Agent.merge var!(config_agent, Bake.Config),
         [{:target, [{unquote(name), unquote(opts)}]}]
    end
  end

  def filter_target(config, target) when is_binary(target), do: filter_target(config, String.to_atom(target))
  def filter_target(config, :all), do: config
  def filter_target(config, target) do
    target_config = (config[:target] || [])
      |> Keyword.take([target])
    case target_config do
      [] -> []
      target_config ->
        config
          |> Keyword.delete(:target)
          |> Keyword.merge([target: target_config])
    end
  end
end
