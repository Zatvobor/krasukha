ExUnit.configure(exclude: [external: true])
ExUnit.start()

defmodule EventHandler do
  require Logger
  use GenEvent
  def handle_event(event, %{pid: pid} = state) do
    send(pid, event)
    {:ok, state}
  end
  def init([pid]), do: {:ok, %{pid: pid}}
end
