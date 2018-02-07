defmodule IntroGenStage.StateServer do
  use GenServer
  require Logger
  alias IntroGenStage.Utils

  @interval 5000

  # Client

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def process(pid, event) do
    GenServer.call(pid, {:process, event})
  end

  # Server (callbacks)

  def init(args) do
    Process.send_after(self(), :tick, @interval)
    {:ok, args}
  end

  def handle_call({:process, event}, _from, state) do
    payload = Utils.transform(event)

    if Utils.expired?(state, payload) do
      Utils.flush(payload)
    end
    new_state = Utils.update(state, payload)

    {:reply, :ok, new_state}
  end

  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end

  def handle_info(:tick, state) do
    Logger.info("tick #{inspect state}")

    # iterate all payload and flush the timeout one
    {new_state, payloads} = Utils.update_all(state)
    Enum.each(payloads, &Utils.flush/1)

    Process.send_after(self(), :tick, @interval)
    {:noreply, new_state}
  end
end
