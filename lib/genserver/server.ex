defmodule IntroGenStage.Server do
  use GenServer
  require Logger

  # Client

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def process(pid, event) do
    GenServer.call(pid, {:process, event})
  end

  # Server (callbacks)

  def handle_call({:process, event}, _from, state) do
    Logger.info("processing #{inspect(event)}")

    payload = transform(event)
    Logger.info("transform analytics event to history payload #{inspect payload}")

    Logger.info("upsert view history")
    wait(10)

    Logger.info("query mongodb for episode list if necessary")
    wait(5)

    Logger.info("upsert series view history")
    wait(10)

    {:reply, :ok, state}
  end

  def handle_call(request, from, state) do
    # Call the default implementation from GenServer
    super(request, from, state)
  end

  defp transform(event) do
    %{device_id: event.device_id, content_id: to_int(event.ctx), position: to_float(event.value)}
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
