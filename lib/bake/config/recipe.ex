defmodule Bake.Config.Recipe do
  use Bake.Config.Utils

  defmacro __using__(_opts) do
    quote do
      import Bake.Config.Recipe,
        only: [platform: 1, name: 1, description: 1, arch: 1,
          version: 1, maintainers: 1, meta: 1, toolchain: 1]
      {:ok, agent} = Bake.Config.Agent.start_link
      var!(config_agent, Bake.Config) = agent
    end
  end

  defmacro platform(platform), do: single_merge(:platform, platform)
  defmacro arch(arch), do: single_merge(:arch, arch)
  defmacro name(name), do: single_merge(:name, name)
  defmacro description(description), do: single_merge(:description, description)
  defmacro version(version), do: single_merge(:version, version)
  defmacro maintainers(maintainers), do: single_merge(:maintainers, maintainers)
  defmacro toolchain(toolchain), do: single_merge(:toolchain, toolchain)
  defmacro meta(meta), do: single_merge(:meta, meta)

  defp single_merge(key, value) do
    quote do
    Bake.Config.Agent.merge var!(config_agent, Bake.Config),
       [{unquote(key), unquote(value)}]
    end
  end

end
