alias Krasukha.{HTTP, WAMP, Helpers}

defmodule Krasukha.MarketsGen do
  use GenServer
  use Krasukha.Helpers.EventGen

  @moduledoc false

  @doc false
  def start_link(preflight_opts \\ []) do
    GenServer.start_link(__MODULE__, preflight_opts, [name: :markets])
  end

  @doc false
  def init(preflight_opts) do
    %{subscriber: subscriber} = WAMP.connection()

    state = %{}
      |> Map.merge(%{subscriber: subscriber})
      |> Map.merge(__create_ticker_table())
      |> Map.merge(__create_gen_event())

    # applies preflight setup
    state = apply_preflight_opts(state, preflight_opts, __MODULE__)

    {:ok, state}
  end

  @doc false
  defdelegate apply_preflight_opts(state, preflight_opts, mod), to: Helpers.Gen

  @doc false
  def __create_ticker_table do
    ticker = :ets.new(:ticker, [:set, :protected, {:read_concurrency, true}])
    %{ticker: ticker}
  end

  # Server (callbacks)

  @doc false
  def handle_call({:subscriber, subscriber}, _from, state) do
    {:reply, :ok, Map.put(state, :subscriber, subscriber)}
  end

  @doc false
  def handle_call(:ticker_tid, _from, %{ticker: tid} = state) do
    {:reply, tid, state}
  end

  @doc false
  def handle_call(:clean_ticker, _from, %{ticker: tid} = state) do
    :true = :ets.delete_all_objects(tid)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call(:fetch_ticker, _from, state) do
    new_state = fetch_ticker(state)
    {:reply, new_state.fetch_ticker_result, new_state}
  end

  @doc false
  def handle_call(:subscribe_ticker, _from, state) do
    new_state = subscribe_ticker(state)
    {:reply, {:ok, new_state.ticker_subscription}, new_state}
  end

  @doc false
  def handle_call(:unsubscribe_ticker, _from, state) do
    new_state = unsubscribe_ticker(state)
    {:reply, new_state.unsubscribed, new_state}
  end

  @doc false
  defdelegate handle_call(do_nothing, from, state), to: Helpers.Gen

  @doc false
  def handle_info({_module, _from, %{args: args}} = _message, state) when is_list(args) do
    :ok = update_ticker(state, args)
    {:noreply, state}
  end

  @doc false
  def terminate(_reason, state) do
    with subscribe_ticker when is_integer(subscribe_ticker) <- state[:ticker_subscription], do: unsubscribe_ticker(state)
  end


  # Client API

  @doc false
  def subscribe_ticker(%{subscriber: subscriber} = state) do
    {:ok, ticker_subscription} = WAMP.subscribe(subscriber, "ticker")
    Map.put(state, :ticker_subscription, ticker_subscription)
    |> Map.delete(:unsubscribed)
  end

  @doc false
  def unsubscribe_ticker(%{subscriber: subscriber, ticker_subscription: ticker_subscription} = state) do
    unsubscribed = WAMP.unsubscribe(subscriber, ticker_subscription)
    Map.delete(state, :ticker_subscription)
    |> Map.put(:unsubscribed, unsubscribed)
  end

  @doc false
  def fetch_ticker(state) do
    {:ok, 200, payload} = HTTP.PublicAPI.return_ticker()
    result = fetch_ticker(state, payload)
    Map.put(state, :fetch_ticker_result, result)
  end

  @doc false
  def fetch_ticker_object_spec, do: %{currencyPair: 1, baseVolume: 2, high24hr: 3, highestBid: 4, id: 5, isFrozen: 6, last: 7, low24hr: 8, lowestAsk: 9, percentChange: 10, quoteVolume: 11}
  def fetch_ticker(%{ticker: tid} = state, payload) do
    Enum.map(payload, fn({k, v}) ->
      object = ([ k | (Map.values(v) |> Enum.map(fn(e) -> Helpers.String.to_float(e) end)) ] |> List.to_tuple)
      :true = :ets.insert(tid, object)
      :ok = notify(state, {:fetch_ticker, object})
    end)
    :ok
  end

  @doc false
  def update_ticker_object_spec(), do: %{currencyPair: 1, last: 2, lowestAsk: 3, highestBid: 4, percentChange: 5, baseVolume: 6, quoteVolume: 7, isFrozen: 8, '24hrHigh': 9, '24hrLow': 10}
  def update_ticker(%{ticker: tid} = state, [_, _, _, [h|t]]) do
    object = ([ Helpers.String.to_atom(h) | Enum.map(t, fn(e) -> Helpers.String.to_float(e) end) ] |> List.to_tuple)
    :true = :ets.insert(tid, object)
    :ok = notify(state, {:update_ticker, object})
    :ok
  end
end
