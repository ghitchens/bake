defmodule Bake.Utils.Brew do
  require Logger

  def installed? do
    package_installed? "brew"
  end

  def package_installed?(package) do
    try do
      {_, 0} = System.cmd("which", [package])
      true
    rescue
      _e -> false
    end
  end

  def install(package) do
    unless installed?, do: raise "You must install homebrew to install the package #{inspect package}"
    try do
      {_, 0} = System.cmd("brew", ["install", package])
      {:ok, package}
    rescue
      e -> {:error, e}
    end
  end
end
