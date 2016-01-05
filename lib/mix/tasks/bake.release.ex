defmodule Mix.Tasks.Bake.Release do
  use Mix.Task
  use ExAws.S3.Client

  def config_root, do: Application.get_all_env(:ex_aws)

  require Logger

  def run(_) do
    Application.ensure_started(:porcelain)
    Application.ensure_started(:httpoison)
    HTTPoison.start
    version = Mix.Project.config[:version]
    Bake.Shell.info "=> Releasing Version #{version} of bake"
    stream = IO.binstream(:standard_io, :line)
    env = [
      {"MIX_ENV", System.get_env("MIX_ENV")}
    ]
    bucket = Application.get_env(:bakeware, :bucket)
    Porcelain.shell("mix deps.get && mix compile && mix escript.build", env: env, out: stream)
    archive_name = "bake-#{version}.tar.gz"
    Bake.Shell.info "=> Uploading to S3"
    Porcelain.shell("tar cfz #{archive_name} bake", dir: "/usr/local/bin", out: stream)
    tar_file = File.read!("/usr/local/bin/#{archive_name}")
    opts = [acl: :public_read]
    Mix.Utils.S3.upload(bucket, "/bake/#{archive_name}", tar_file, opts)

    Bake.Shell.info "=> Making #{version} Permanent"
    Porcelain.shell("heroku config:set BAKE_VERSION=#{version} -a bakeware", out: stream)
    Bake.Shell.info "=> Release Finished"
  end

end
