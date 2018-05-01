defmodule EventHandler do
  require Logger
  use GenEvent
  def handle_event(event, %{pid: pid} = state) do
    send(pid, event)
    {:ok, state}
  end
  def init([pid]), do: {:ok, %{pid: pid}}
end


defmodule Krasukha.SharedEventManagerBehavior do
  defmacro __using__(_) do
    quote do
      describe "event manager" do
        test "calls :create_event_manager", %{server: pid} do
          event_manager = GenServer.call(pid, :create_event_manager)
          assert Process.alive?(event_manager)
        end
      end
    end
  end
end
