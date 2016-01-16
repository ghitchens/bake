defmodule Bake.Utils.Vagrant do
  alias Bake.Utils

  require Logger

  def init do
    File.mkdir_p!(Utils.oven_dir)
    install_check
    vagrantfile_init
  end

  def up do

  end

  defp install_check do
    vagrant =
    try do
      {version_string, _code} = System.cmd("vagrant", ["--version"])
      version = String.strip(version_string)
        |> String.split(" ")
        |> List.last
      {:ok, version}
    rescue
      e -> {:error, e}
    end
    case vagrant do
      {:ok, _version} -> nil
        #TODO Check version number to ensure compatibility
      {:error, _} -> install
    end
    {_, version} = vagrant
    Logger.debug "[oven] Vagrant Version: #{inspect version}"
  end

  defp install do
    #TODO install vagrant from homebrew
    # If homebrew is not installed, prompt the User
    # to install homebrew
  end

  defp vagrantfile_init do
    case File.read(Utils.oven_dir <> "/Vagrantfile") do
      {:ok, _file} ->
        Logger.debug "[oven] Vagrantfile Exists"
        nil
        # TODO check to ensure that the recipe has not changed.
      _ -> vagrantfile_create
    end
  end

  defp vagrantfile_create do
    Logger.debug "[oven] Vagrantfile Creating"
    vagrantfile_template = :code.priv_dir(:bake)
      |> to_string
    vagrantfile_template = vagrantfile_template <> "/oven/Vagrantfile"

    File.cp_r(vagrantfile_template, (Utils.oven_dir <> "/Vagrantfile"))
  end

end
