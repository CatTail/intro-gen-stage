defmodule IntroGenStage.StateServer do
  use GenServer
  require Logger

  @interval 1000

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
    Logger.info("processing #{inspect(event)}")

    payload = transform(event)
    Logger.info("transform analytics event to history payload #{inspect payload}")

    new_state = update_or_flush(state, payload)

    {:reply, :ok, new_state}
  end

  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end

  def handle_info(:tick, state) do
    Logger.info("tick #{inspect state}")

    # iterate all payload and flush the timeout one
    new_state = state
    |> Map.keys()
    |> Enum.reduce(state, fn (key, acc) -> 
      {device_id, content_id} = parse_state_key(key)
      %{position: position, time: time} = Map.get(acc, key)
      update_or_flush(acc, %{device_id: device_id, content_id: content_id, position: position, time: time})
    end)

    Process.send_after(self(), :tick, @interval)
    {:noreply, new_state}
  end

  defp update_or_flush(state, payload) do
    key = get_state_key({payload.device_id, payload.content_id})
    new_value = %{position: payload.position, time: payload.time}

    {_, new_state} = Map.get_and_update(state, key, fn old_value ->
      case old_value do
        %{position: position, time: time} ->
          if payload.time + @interval > now() do
            flush(payload)
            # remove key from state
            :pop
          else
            {old_value, new_value}
          end
        nil ->
          {nil, new_value}
      end
    end)
    new_state
  end

  defp flush(payload) do
    Logger.info("upsert view history")
    wait(10)

    Logger.info("query mongodb for episode list if necessary")
    wait(5)

    Logger.info("upsert series view history")
    wait(10)
  end

  defp now() do
    Timex.now() |> Timex.to_unix()
  end

  defp get_state_key(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.join("#")
  end

  defp parse_state_key(str) do
    str
    |> String.split("#")
    |> List.to_tuple()
  end

  defp transform(event) do
    %{device_id: event.device_id, content_id: to_int(event.ctx), position: to_float(event.value), time: now()}
  end

  defp to_int(str) do
    elem(Integer.parse(str), 0)
  end

  defp to_float(str) do
    elem(Float.parse(str), 0)
  end

  defp wait(timeout) do
    :timer.sleep(timeout * 100)
  end
end
