require Logger

defmodule Krasukha.OrderBookGen do
  @moduledoc false

  use GenServer

  alias Krasukha.{OrderBookAgent, HTTP, WAMP}


  @doc false
  def start_link(currency_pair) when is_binary(currency_pair) do
    options = [name: String.to_atom(currency_pair)]
    GenServer.start_link(__MODULE__, [currency_pair], options)
  end

  @doc false
  def init([currency_pair]) do
    storage = OrderBookAgent.new_storage() # used here for keeping writing ownership
    {:ok, order_book} = OrderBookAgent.start_link(storage)

    # turn on listening of order book updates
    # {:ok, subscriber, subscription} = listenOrderBookUpdates(currency_pair)

    # {:ok, [subscriber, subscription, order_book]}
    {:ok, %{currency_pair: currency_pair, order_book: order_book}}
  end

  @doc false
  def terminate(_reason, %{order_book: order_book} = _state) do
  # def terminate(_reason, %{order_book: order_book, subscriber: subscriber, subscription: subscription} = _state) do
    # :ok = Spell.call_unsubscribe(subscriber, subscription)
    # :ok = Spell.close(subscriber)
    :ok = OrderBookAgent.stop(order_book)

    :ok
  end

  # Server (callbacks)

  @doc false
  def handle_call(:clean_order_book, _from, %{order_book: agent} = state) do
    {:reply, OrderBookAgent.delete_all_objects(agent), state}
  end

  @doc false
  def handle_call(:fetch_order_book, _from, %{currency_pair: currency_pair, order_book: agent} = state) do
    {:reply, fetchOrderBook([currencyPair: currency_pair, depth: 1], agent), state}
  end

  @doc false
  def handle_call({:fetch_order_book, [depth: depth]} = _msg, _from, %{currency_pair: currency_pair, order_book: agent} = state) do
    {:reply, fetchOrderBook([currencyPair: currency_pair, depth: depth], agent), state}
  end

  # Client API

  @doc false
  def fetchOrderBook(params, agent) when is_list(params) and is_pid(agent) do
    {:ok, 200, %{asks: asks, bids: bids, isFrozen: "0"}} = HTTP.returnOrderBook(params)
    [asks_book_tid, bids_book_tid] = OrderBookAgent.book_tids(agent)
    flow = [{asks, asks_book_tid, :ask}, {bids, bids_book_tid, :bid}]
    Enum.each(flow, fn({records, tid, type}) ->
        Enum.each(records, fn([price, amount]) -> :ets.insert(tid, {price, amount, type}) end)
    end)

    :ok
  end

  @doc false
  def listenOrderBookUpdates(currency_pair) when is_binary(currency_pair) do
    {:ok, subscriber} = Spell.connect(WAMP.url, realm: "realm1")
    {:ok, subscription} = Spell.call_subscribe(subscriber, currency_pair)

    # case Spell.receive_event(subscriber, subscription) do
    #   {:ok, event}     -> Logger.info(inspect(event))
    #   {:error, reason} -> {:error, reason}
    # end

    {:ok, subscriber, subscription}
  end
end
