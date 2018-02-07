defmodule IntroGenStage.Server do
  use GenServer
  require Logger
  alias IntroGenStage.Utils

  # Client

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def process(pid, event) do
    GenServer.call(pid, {:process, event})
  end

  # Server (callbacks)

  def handle_call({:process, event}, _from, state) do
    payload = Utils.transform(event)

    Utils.flush(payload)

    {:reply, :ok, state}
  end

  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end
end
