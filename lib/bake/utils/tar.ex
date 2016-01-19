defmodule Bake.Utils.Tar do

  @version "1"
  @default_files ~w(*)

  def pack(config, cleanup_tarball? \\ true) do
    content_path = "#{config[:name]}-#{config[:version]}-contents.tgz"
    path = "#{config[:name]}-#{config[:version]}.tar"

    files = expand_paths(@default_files, File.cwd!)
    files =
      Enum.map(files, fn
        {name, bin} -> {String.to_char_list(name), bin}
        name -> String.to_char_list(name)
      end)
    :ok = :erl_tar.create(content_path, files)
    contents = File.read!(content_path)

    config = :erlang.term_to_binary(config)
    blob = @version <> config <> contents
    checksum = :crypto.hash(:sha256, blob) |> Base.encode16

    files = [
      {'VERSION', @version},
      {'CHECKSUM', checksum},
      {'package.config', config},
      {'contents.tar.gz', contents} ]
    :ok = :erl_tar.create(path, files)
    tar = File.read!(path)
    File.rm!(content_path)
    if cleanup_tarball?, do: File.rm!(path)
    tar
  end

  def unpack(binary) do
    case :erl_tar.extract({:binary, binary}, [:memory]) do
      {:ok, files} ->
        files = Enum.into(files, %{}, fn {name, binary} -> {List.to_string(name), binary} end)
      {:error, reason} ->
        {:error, inspect reason}
    end
  end

  def unpack(binary, :compressed) do
    case :erl_tar.extract({:binary, binary}, [:compressed, :memory]) do
      {:ok, files} ->
        files = Enum.into(files, %{}, fn {name, binary} -> {List.to_string(name), binary} end)
      {:error, reason} ->
        {:error, inspect reason}
    end
  end

  def expand_paths(paths, dir) do
    expand_dir = Path.expand(dir)

    paths
    |> Enum.map(&Path.join(dir, &1))
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.flat_map(&dir_files/1)
    |> Enum.map(&Path.expand/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq
    |> Enum.map(&Path.relative_to(&1, expand_dir))
  end

  def dir_files(path) do
    if File.dir?(path) do
      Path.wildcard(Path.join(path, "**"))
    else
      [path]
    end
  end
end
