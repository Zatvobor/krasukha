defmodule Krasukha.Helpers.EventGen do
  @moduledoc false

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc false
      def create_event_manager(state) do
        Map.merge(state, __create_gen_event())
      end

      @doc false
      def __create_gen_event() do
        {:ok, event_manager} = GenEvent.start_link()
        %{event_manager: event_manager}
      end

      # GenServer (callbacks)

      @doc false
      def handle_call(:create_event_manager, _from, state) do
        new_state = create_event_manager(state)
        {:reply, new_state.event_manager, new_state}
      end
      @doc false
      def handle_call(:event_manager, _from, %{event_manager: event_manager} = state) do
        {:reply, event_manager, state}
      end

      defp notify(%{event_manager: event_manager}, event), do: GenEvent.notify(event_manager, event)
      defp notify(%{}, _event), do: :ok
    end
  end
end
