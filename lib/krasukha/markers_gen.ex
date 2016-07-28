defmodule Krasukha.MarketsGen do
  @moduledoc false

  use GenServer

  alias Krasukha.{HTTP, WAMP}


  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [name: :markets])
  end

  @doc false
  def init(:ok) do
    %{subscriber: subscriber} = WAMP.connection()
    ticker = :ets.new(:ticker, [:set, :protected, {:read_concurrency, true}])

    {:ok, %{subscriber: subscriber, ticker: ticker}}
  end

  # Server (callbacks)

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
  def handle_call(:fetch_ticker, _from, %{ticker: tid} = state) do
    {:ok, 200, payload} = HTTP.return_ticker()
    fetched = fetch_ticker(tid, payload)
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
  def handle_info({_module, _from, %{args: args}} = _message, %{ticker: tid} = state) when is_list(args) do
    :ok = update_ticker(tid, args)
    {:noreply, state}
  end


  # Client API

  import Krasukha.HTTP.PublicAPI, only: [to_float: 1]

  @doc false
  def fetch_ticker(tid, payload) do
    Enum.map(payload, fn({k, v}) ->
      object = ([ to_string(k) | (Map.values(v) |> Enum.map(fn(e) -> to_float(e) end)) ] |> List.to_tuple)
      :true = :ets.insert(tid, object)
    end)
    :ok
  end

  @doc false
  def update_ticker(tid, [_, _, _, [h|t]]) do
    object = ([ h | Enum.map(t, fn(e) -> to_float(e) end) ] |> List.to_tuple)
    :true = :ets.insert(tid, object)
    :ok
  end
end
