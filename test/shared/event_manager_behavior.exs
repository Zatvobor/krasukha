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
      describe "event manager GenServer" do
        test "calls :create_event_manager", %{server: pid} do
          event_manager = GenServer.call(pid, :create_event_manager)
          assert Process.alive?(event_manager)
        end

        test "calls :event_manager", %{server: pid} do
          GenServer.call(pid, :create_event_manager)
          event_manager = GenServer.call(pid, :event_manager)
          assert Process.alive?(event_manager)
        end

        test "callls {:event_manager, pid}", %{server: pid} do
          {:ok, event_manager} = GenEvent.start_link()
          :ok = GenServer.call(pid, {:event_manager, event_manager})
          event_manager = GenServer.call(pid, :event_manager)
          assert Process.alive?(event_manager)
        end
      end
    end
  end
end
