defmodule Bake.Mixfile do
  use Mix.Project

  def project do
    [app: :bake,
     version: "0.2.7-dev",
     elixir: "~> 1.1",
     escript: [main_module: Bake.Cli, name: escript_name, path: escript_path],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_options: elixirc_options(Mix.env),
     elixirc_paths: elixirc_paths(Mix.env),
     #aliases: aliases,
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison, :poison, :crypto, :ssl, :ssh, :sshex, :mix, :porcelain, :phoenix_channel_client],mod: {Bake, []}]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 1.5.0"},
      {:git_cli, "~> 0.1.0"},
      {:sshex, "~> 1.3"},
      {:porcelain, "~> 2.0"},
      {:sweet_xml, "~> 0.5"},
      {:ex_aws, "~> 0.4.11"},
      {:table_rex, "~> 0.8"},
      {:phoenix_channel_client, github: "mobileoverlord/phoenix_channel_client"}
    ]
  end

  defp elixirc_options(:prod), do: [debug_info: false]
  defp elixirc_options(_),     do: []

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp escript_path do
    {platform, 0} = System.cmd("uname", ["-s"])
    platform
    |> String.strip
    |> String.downcase
    |> escript_platform
  end

  defp escript_platform(<<"darwin", _tail :: binary >>), do: "/usr/local/bin/#{escript_name}"
  defp escript_platform(_), do: Path.expand("~/.bake/bin/#{escript_name}")
  defp escript_name, do: "bake"

end
