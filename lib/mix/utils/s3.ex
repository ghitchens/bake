defmodule Mix.Utils.S3 do
  use ExAws.S3.Client

  def config_root, do: Application.get_all_env(:ex_aws)

  def upload(bucket, path, data, opts \\ []) do
    put_object!(bucket, path, data, opts)
  end
end
