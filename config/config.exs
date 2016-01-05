# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :bake, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:bake, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
config :porcelain, driver: Porcelain.Driver.Basic
config :ex_aws, :httpoison_opts,
  recv_timeout: 60_000,
  hackney: [pool: false]

config :ex_aws, :s3,
  scheme: "http://",
  host: "s3.amazonaws.com",
  region: "us-east-1"

config :ex_aws,
  http_client: ExAws.Request.HTTPoison,
  access_key_id: [{:system, "BAKE_AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "BAKE_AWS_SECRET_ACCESS_KEY"}, :instance_role]

import_config "#{Mix.env}.exs"
