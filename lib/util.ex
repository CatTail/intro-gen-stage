defmodule IntroGenStage.Utils do
  require Logger

  def flush_expired(state) do
    state
    |> Map.keys()
    |> Enum.reduce(state, fn (key, acc) -> 
      {device_id, content_id} = parse_state_key(key)
      %{position: position, time: time} = Map.get(acc, key)
      update_or_flush(acc, %{device_id: device_id, content_id: content_id, position: position, time: time})
    end)
  end

  def update_or_flush(state, payload) do
    key = get_state_key({payload.device_id, payload.content_id})
    new_value = %{position: payload.position, time: payload.time}

    {_, new_state} = Map.get_and_update(state, key, fn old_value ->
      case old_value do
        %{position: position, time: time} ->
          if payload.time + 1000 > now() do
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

  def flush(payload) do
    Logger.info("upsert view history")
    wait(10)

    Logger.info("query mongodb for episode list if necessary")
    wait(5)

    Logger.info("upsert series view history")
    wait(10)
  end

  def now() do
    Timex.now() |> Timex.to_unix()
  end

  def get_state_key(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.join("#")
  end

  def parse_state_key(str) do
    str
    |> String.split("#")
    |> List.to_tuple()
  end

  def transform(event) do
    payload = %{device_id: event.device_id, content_id: to_int(event.ctx), position: to_float(event.value), time: now()}
    Logger.info("transform analytics event #{inspect event} to history payload #{inspect payload}")
    payload
  end

  def to_int(str) do
    elem(Integer.parse(str), 0)
  end

  def to_float(str) do
    elem(Float.parse(str), 0)
  end

  def wait(timeout) do
    :timer.sleep(timeout * 100)
  end
end
