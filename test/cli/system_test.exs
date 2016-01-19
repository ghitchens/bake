defmodule Bake.Cli.SystemTest do
  use BakeTest.Case, async: false
  import Bake.Cli.Menu
  require Logger

  setup do
    opts = %{
      bakefile: "test/support/Bakefile",
      target: "bbb"
    }
    {:ok, %{opts: opts}}
  end

  test "Get system for a target", context do
    target = Map.get(context.opts, :target)
    |> String.to_atom

    {bakefile_path, target_config, _target} = bakefile(Map.get(context.opts, :bakefile), target)
    platform = target_config[:platform]
    adapter = adapter(platform)

    {:bbb, system} = Bake.Cli.System.get(context.opts)
    assert File.dir?(adapter.systems_path <> "/#{system.username}/#{system.name}-#{system.version}")

    # Check the lock file

    lock_path = bakefile_path
    |> Path.dirname
    lock_path = lock_path <> "/Bakefile.lock"
    assert File.exists? lock_path

    lock_file = Bake.Config.Lock.read(lock_path)
    lock_targets = lock_file[:targets]
    assert ["#{system.username}/#{system.name}": system.version] == Keyword.get(lock_targets, target)
  end

  test "Clean all systems", context do
    opts = Map.put(context.opts, :all, true)

    {_bakefile_path, target_config, _target} = bakefile(Map.get(context.opts, :bakefile), Map.get(context.opts, :target))
    platform = target_config[:platform]
    adapter = adapter(platform)

    send self, {:mix_shell_input, :yes?, true}
    assert {:mix_shell, :info, ["All nerves systems have been removed"]} = Bake.Cli.System.clean(opts)
    # TODO assert that all systems have been removed form the system directory
    refute File.dir?(adapter.systems_path)
  end

  test "Clean unknown system raises error", context do
    opts = Map.put(context.opts, :target, "foo")
    assert_raise Bake.Error, "Bakefile does not contain definition for target foo", fn ->
      Bake.Cli.System.clean(opts)
    end
  end

  #TODO Test update system

end
