defmodule Krasukha.MarketsGen do
  @moduledoc false

  use GenServer

  import String, only: [to_atom: 1]

  alias Krasukha.{HTTP, WAMP}


  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: :markets])
  end

  @doc false
  def init(:ok) do
    %{subscriber: subscriber} = WAMP.connection()

    state = %{}
      |> Map.merge(%{subscriber: subscriber})
      |> Map.merge(__create_ticker_table())
      |> Map.merge(__create_gen_event())

    {:ok, state}
  end

  @doc false
  def __create_ticker_table do
    ticker = :ets.new(:ticker, [:set, :protected, {:read_concurrency, true}])
    %{ticker: ticker}
  end

  @doc false
  def __create_gen_event do
    {:ok, event_manager} = GenEvent.start_link()
    %{event_manager: event_manager}
  end

  # Server (callbacks)

  @doc false
  def handle_call(:event_manager, _from, %{event_manager: event_manager} = state) do
    {:reply, event_manager, state}
  end

  @doc false
  def handle_call({:subscriber, subscriber}, _from, state) do
    {:reply, :ok, Map.put(state, :subscriber, subscriber)}
  end

  @doc false
  def handle_call(:ticker, _from, %{ticker: tid} = state) do
    {:reply, tid, state}
  end

  @doc false
  def handle_call(:clean_ticker, _from, %{ticker: tid} = state) do
    :true = :ets.delete_all_objects(tid)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call(:fetch_ticker, _from, state) do
    {:ok, 200, payload} = HTTP.return_ticker()
    fetched = fetch_ticker(state, payload)
    {:reply, fetched, state}
  end

  @doc false
  def handle_call(:subscribe_ticker, _from, %{subscriber: subscriber} = state) do
    {:ok, ticker_subscription} = WAMP.subscribe(subscriber, "ticker")
    {:reply, {:ok, ticker_subscription},  Map.put(state, :ticker_subscription, ticker_subscription)}
  end

  @doc false
  def handle_call(:unsubscribe_ticker, _from, %{subscriber: subscriber, ticker_subscription: ticker_subscription} = state) do
    unsubscribed = WAMP.unsubscribe(subscriber, ticker_subscription)
    {:reply, unsubscribed, Map.delete(state, :ticker_subscription)}
  end

  @doc false
  def handle_info({_module, _from, %{args: args}} = _message, state) when is_list(args) do
    :ok = update_ticker(state, args)
    {:noreply, state}
  end

  @doc false
  def terminate(_reason, state) do
    if state[:ticker_subscription], do: GenServer.call(self, :unsubscribe_ticker)
    :ok
  end


  # Client API

  import Krasukha.HTTP.PublicAPI, only: [to_float: 1]

  @doc false
  def fetch_ticker(%{ticker: tid} = state, payload) do
    Enum.map(payload, fn({k, v}) ->
      object = ([ to_atom(k) | (Map.values(v) |> Enum.map(fn(e) -> to_float(e) end)) ] |> List.to_tuple)
      :ok = notify(state, {:fetch_ticker, object})
      :true = :ets.insert(tid, object)
    end)
    :ok
  end

  @doc false
  def update_ticker(%{ticker: tid} = state, [_, _, _, [h|t]]) do
    object = ([ to_atom(h) | Enum.map(t, fn(e) -> to_float(e) end) ] |> List.to_tuple)
    :ok = notify(state, {:update_ticker, object})
    :true = :ets.insert(tid, object)
    :ok
  end

  defp notify(%{event_manager: event_manager}, event), do: GenEvent.notify(event_manager, event)
  defp notify(%{}, _event), do: :ok
end
