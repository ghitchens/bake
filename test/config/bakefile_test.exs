defmodule Bake.Config.BakefileTest do
  use BakeTest.Case

  test "Bake can parse Bakefile" do
    assert {:ok, _} = Bake.Config.read!("test/support/Bakefile")
  end


end
