defmodule Bake.Config.Agent do

  require Logger

  @typep config :: Keyword.t

  @spec start_link() :: {:ok, pid}
  def start_link do
    Agent.start_link fn -> [] end
  end

  @spec stop(pid) :: :ok
  def stop(agent) do
    Agent.stop(agent)
  end

  @spec get(pid) :: config
  def get(agent) do
    Agent.get(agent, &(&1))
  end

  @spec merge(pid, config) :: config
  def merge(agent, new_config) do
    Agent.update(agent, &Bake.Config.merge(&1, new_config))
  end
end
