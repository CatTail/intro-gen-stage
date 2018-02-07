alias IntroGenStage.Utils

defmodule IntroGenStage.PayloadProducer3 do
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

defmodule IntroGenStage.PayloadAggregator3 do
  use GenStage
  require Logger

  @interval 5000

  # Client

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: opts[:name])
  end

  def process(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:process, event}, timeout)
  end

  # Server (callbacks)

  def init(opts) do
    Process.send_after(self(), :tick, @interval)

    selector = fn (%{device_id: device_id}) -> :erlang.phash2(device_id, opts[:size]) === opts[:id] end
    subscribe_to = Enum.map(opts[:publishers], &({&1, selector: selector}))

    {:producer_consumer, %{}, subscribe_to: subscribe_to}
  end

  def handle_events(events, _from, state) do
    {new_state, payloads} = Enum.reduce(events, {state, []}, fn (event, {acc, payloads}) ->
      payloads = if Utils.expired?(acc, event), do: [event | payloads], else: payloads
      new_state = Utils.update(acc, event)
      {new_state, payloads}
    end)

    {:noreply, payloads, new_state}
  end

  def handle_info(:tick, state) do
    Logger.info("tick #{inspect self()} #{inspect state}")

    # iterate all payload and flush the timeout one
    {new_state, payloads} = Utils.update_all(state)

    Process.send_after(self(), :tick, @interval)
    {:noreply, payloads, new_state}
  end
end

defmodule IntroGenStage.PayloadWriter3 do
  use GenStage
  require Logger


  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:consumer, :state_doesnt_matter, subscribe_to: opts[:publishers]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      :timer.sleep(1000)
      Utils.flush(event)
    end

    # As a consumer we never emit events
    {:noreply, [], state}
  end
end
