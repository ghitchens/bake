defmodule Mix.Utils.S3 do
  use ExAws.S3.Client, otp_app: :bake

  def upload(bucket, path, data, opts \\ []) do
    put_object!(bucket, path, data, opts)
  end
end
