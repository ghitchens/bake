defmodule Bake.Config.Utils do

  defmacro __using__(_) do
    quote do
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
    end
  end
end
