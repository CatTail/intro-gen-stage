alias IntroGenStage.Utils

defmodule IntroGenStage.PayloadProducer do
  use GenStage
  require Logger

  # Client

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def process(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:process, event}, timeout)
  end

  # Server (callbacks)

  def init(:ok) do
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_call({:process, event}, from, {queue, demand}) do
    event = Utils.transform(event)
    dispatch_events(:queue.in({from, event}, queue), demand, [])
  end

  def handle_demand(incoming_demand, {queue, demand}) do
    dispatch_events(queue, incoming_demand + demand, [])
  end

  defp dispatch_events(queue, demand, events) do
    with d when d > 0 <- demand,
         {{:value, {from, event}}, queue} <- :queue.out(queue) do
      GenStage.reply(from, :ok)
      dispatch_events(queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end

defmodule IntroGenStage.PayloadAggregator do
  use GenStage
  require Logger

  @interval 1000

  # Client

  def start_link() do
    GenStage.start_link(__MODULE__, %{})
  end

  def process(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:process, event}, timeout)
  end

  # Server (callbacks)

  def init(state) do
    Process.send_after(self(), :tick, @interval)

    {:consumer, state, subscribe_to: [IntroGenStage.PayloadProducer]}
  end

  def handle_events(events, _from, state) do
    new_state = Enum.reduce(events, state, fn (event, acc) ->
      Utils.update_or_flush(state, event)
    end)

    {:noreply, [], new_state}
  end

  def handle_info(:tick, state) do
    Logger.info("tick #{inspect state}")

    # iterate all payload and flush the timeout one
    new_state = Utils.flush_expired(state)

    Process.send_after(self(), :tick, @interval)
    {:noreply, [], new_state}
  end
end

defmodule IntroGenStage.PayloadWriter do
  use GenStage
  require Logger
end