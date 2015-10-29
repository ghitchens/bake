# defmodule Bake.Adapters.Nerves.Toolchain do
#   require Logger
#
#   def get(target_config) do
#     target_config[:target]
#       |> Enum.reduce(HashSet.new, fn({k, config}, acc) ->
#         case Bake.Api.System.toolchain(config[:recipe]) do
#           {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
#             items = Poison.decode!(body)
#               |> Map.get("data")
#             Enum.reduce(items, acc, &(HashSet.put(&2, &1)))
#           {_, response} ->
#             Bake.Shell.error("Failed to get toolchain for #{k}")
#             Bake.Utils.print_response_result(response)
#             acc
#         end
#       end)
#       |> HashSet.to_list
#       |> toolchain_items
#   end
#
#   defp toolchain_items(items) do
#     Enum.each(items, fn(%{"path" => path, "file" => file} = item)->
#       bake_home = BakeUtils.bake_home
#       {file_name, _} = explode_file_name(file)
#       case File.dir?(bake_home <> path <> file_name) do
#         true ->
#           toolchain_version(item)
#         false ->
#           toolchain_install(item)
#       end
#     end)
#   end
#
#   defp toolchain_version(%{"type" => type, "version" => version} = item) do
#     Bake.Shell.info("Checking #{type} version")
#
#   end
#
#   defp toolchain_install(item) do
#     %{"type" => type,
#     "version" => version,
#     "download" => download,
#     "path" => path,
#     "file" => file} = item
#
#     {file_name, _} = explode_file_name(file)
#     file_path = BakeUtils.bake_home <> path
#     Bake.Shell.info("Installing #{type} #{version}")
#     File.mkdir_p(file_path)
#     case Bake.Utils.download_file(download) do
#       {:ok, %{status_code: status_code, body: body}} when status_code in 200..299 ->
#         tar_file = "/nerves/toolchain/" <>
#         File.write!(tar_file, body)
#         System.cmd("tar", ["-zxf", tar_file], [cd: file_path])
#         File.rm(tar_file)
#         File.write(file_path <> file_name <> "/meta.json", Poison.encode!(item))
#       {_, response} ->
#         Bake.Shell.error("Failed to install #{type} #{version}")
#         Bake.Utils.print_response_result(response)
#     end
#   end
#
#   defp explode_file_name(file) do
#     components = String.split(file, ".")
#     ext = List.last(components)
#     name = List.delete_at(components, -1)
#       |> Enum.join(".")
#     {name, ext}
#   end
#
# end
