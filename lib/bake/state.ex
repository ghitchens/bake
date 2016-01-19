defmodule Bake.State do
  @name __MODULE__
  @default_bake_home "~/.bake"
  @default_nerves_home "~/.nerves"

  require Logger

  def start_link do
    config = Bake.Config.Global.read
    Agent.start_link(__MODULE__, :init, [config], [name: @name])
  end

  def init(config) do
    %{
      bake_home: Path.expand(System.get_env("BAKE_HOME") || @default_bake_home),
      nerves_home: Path.expand(System.get_env("NERVES_HOME") || @default_nerves_home)
    }
  end

  def fetch(key) do
    Agent.get(@name, Map, :fetch, [key])
  end

  def fetch!(key) do
    Agent.get(@name, Map, :fetch!, [key])
  end

  def get(key, default \\ nil) do
    Agent.get(@name, Map, :get, [key, default])
  end

  def put(key, value) do
    Agent.update(@name, Map, :put, [key, value])
  end

end
