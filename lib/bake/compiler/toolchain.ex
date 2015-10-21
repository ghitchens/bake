defmodule Bake.Compiler.Toolchain do

  def fetch(config) do
    # Check the local toolchain to see if it
    #  matches the request for the remote toolchain
    host_arch = get_host_arch

  end

  defp get_host_arch do
    {arch, 0} = System.cmd("uname", ["-s", "-r"])
    arch
  end
end
