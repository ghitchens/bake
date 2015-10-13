defmodule Bake.Oven do
  use GenServer

  require Logger

  alias Bake.Utils
  alias Bake.Utils.Vagrant
  alias Bake.Oven.Message

  @timeout 5000

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init do
    Vagrant.init
    # Check to see if nerves exists
  end

  def preheat(opts \\ []) do
    ensure_started
    GenServer.call(__MODULE__, {:up}, :infinity)
  end

  def halt do
    ensure_started
    GenServer.call(__MODULE__, {:halt}, :infinity)
  end

  def bake(recipe) do
    ensure_started
    GenServer.call(__MODULE__, {:bake, recipe}, :infinity)
  end

  defp ensure_started do
    start_link
  end

  def init(opts) do
    Application.ensure_started(:ssh)
    {:ok, %{
      oven_dir: Utils.oven_dir,
      port: nil,
      client: nil,
      status: :halt,
      recipe: nil,
      queue: [],
      ssh_config: nil,
      ssh_client: nil
    }}
  end

  def handle_call({:up}, _from, %{oven_dir: oven_dir} = s) do
    Logger.debug "[oven] Preheating"
    case vagrant_cmd("status") do
      {:ok, :running} -> nil
      result ->
        vagrant_cmd("up")
        vagrant_cmd("provision")
    end
    {:ok, config} = vagrant_cmd("ssh-config")
    {:reply, :ok, %{s | status: :up, ssh_config: config}}
  end

  def handle_call({:halt}, _from, s) do
    Logger.debug "[oven] Shutting Down"
    vagrant_cmd!("halt")
    {:reply, :ok, s}
  end

  def handle_call({:bake, recipe}, from , %{oven_dir: oven_dir} = s) do
    Logger.debug "[oven] Bake Started"
    #queue = [:ssh, {:cmd, "cd /opt/nerves-sdk", wait: false}, {:cmd, "sudo make #{recipe}", []}, {:cmd, "sudo make", []}]
    queue = [:ssh]
    queue_next
    {:noreply, %{s |client: from, queue: queue}}
  end

  def handle_info(:ssh, %{status: :up, ssh_config: config} = s) do
    Logger.debug "[oven] SSH Connecting"
    {port, _} = Integer.parse(config[:port])
    opts = [
      {:user, String.to_char_list(config[:user])},
      {:password, 'vagrant'},
      {:silently_accept_hosts, true}
    ]
    Logger.debug "[oven] SSH Config: #{inspect config}"
    Logger.debug "[oven] SSH Opts: #{inspect opts}"

    {:ok, conn} = :ssh.connect(
      String.to_char_list(config[:hostname]),
      port,
      opts,
      5000
    )
    Logger.debug "SSH Started: #{inspect conn}"
    stream = SSHEx.stream conn, 'cd /home/vagrant/nerves-sdk && make'
    Stream.each(stream, fn(x) -> send self, x end)
    Stream.run(stream)
    #Logger.debug "SSH Result: #{inspect result}"
    GenServer.reply(s.client, {:ok, conn})
    {:noreply, %{s | status: :baking, ssh_client: conn}}
  end

  def handle_info({:cmd, cmd, opts}, %{oven_dir: oven_dir, port: port} = s) do
    Logger.debug "Opts: #{inspect opts}"
    wait = opts[:wait]
    if wait == nil, do: wait = true
    Port.command(port, cmd <> "\n")
    Logger.debug "[oven] Calling Command: #{inspect cmd} wait: #{inspect wait}"
    if wait == false, do: queue_next
    {:noreply, s}
  end

  def handle_info({:stdout,row}, %{status: :baking, port: port, queue: queue} = s) do
    Logger.debug "[oven] SSH Output #{inspect row}"
    {:noreply, s}
  end

  # Command Generating Output

  def handle_info({port, {:data, char}}, %{status: :ready, port: port, queue: queue} = s) do
    Logger.debug "[oven] #{inspect char}"
    {:noreply, s}
  end

  def handle_info({port, {:data, char}}, %{status: status} = s) do
    output = String.split(char, ",")
    timestamp   =   Enum.fetch!(output, 0)
    target      =   Enum.fetch!(output, 1)
    type        =   Enum.fetch!(output, 2)
    # TODO Need to capture error-exit in type
    data        =   Enum.fetch!(output, 2)
    Logger.debug "[oven] [#{timestamp} | #{inspect target} | #{inspect type}] #{data}"
    {:noreply, %{s | status: status}}
  end

  # Command Completed
  def handle_info({port, {:exit_status, code}}, %{client: client} = s) do
    Logger.debug "Command Complete"
    queue_next
    {:noreply, %{s | port: nil, status: :idle}}
  end

  def handle_info(:queue_next, %{queue: [], client: client} = s) do
    GenServer.reply(client, :ok)
    {:noreply, s}
  end

  def handle_info(:queue_next, %{queue: [task | queue], client: client} = s) do
    Logger.debug "Queue: #{inspect task}"
    send(self, task)
    {:noreply, %{s | queue: queue}}
  end

  defp queue_next do
    send(self, :queue_next)
  end

  defp vagrant_cmd(cmd) do
    Logger.debug "Calling Vagrant Command: #{inspect cmd}"
    try do
      result = vagrant_cmd!(cmd)
      {:ok, result}
    rescue
      e -> {:error, e}
    end
  end

  defp vagrant_cmd!(cmd) do
    System.cmd("vagrant", [cmd, "--machine-readable"], cd: Utils.oven_dir)
      |> Message.parse(String.to_atom(cmd))
  end

end
