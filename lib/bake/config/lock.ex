defmodule Bake.Config.Lock do
  # only for use with bakefile configs
  defmacro __using__(_opts) do

  end

  def read(path) do
    case File.read(path) do
      {:ok, binary} ->
        case decode_term(binary) do
          {:ok, term} -> term
          {:error, _} -> decode_elixir(binary)
        end
      {:error, _} ->
        []
    end
  end

  def update(path, config) do
    content = read(path)
    |> Keyword.merge(config)
    write(path, content)
  end

  def write(path, config) do
    string = encode_term(config)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, string)
  end


  def encode_term(list) do
    list
    |> Enum.map(&[:io_lib.print(&1) | ".\n"])
    |> IO.iodata_to_binary
  end

  def decode_term(string) do
    {:ok, pid} = StringIO.open(string)
    try do
      consult(pid, [])
    after
      StringIO.close(pid)
    end
  end

  defp consult(pid, acc) when is_pid(pid) do
    case :io.read(pid, '') do
      {:ok, term}      -> consult(pid, [term|acc])
      {:error, reason} -> {:error, reason}
      :eof             -> {:ok, Enum.reverse(acc)}
    end
  end

  def decode_elixir(string) do
    {term, _binding} = Code.eval_string(string)
    term
  end
end
