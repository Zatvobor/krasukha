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
    {:ok, order_book} = OrderBookAgent.start_link()
    %{subscriber: subscriber} = WAMP.connection()

    # turn on listening of order book updates
    # case Spell.receive_event(subscriber, subscription) do
    #   {:ok, event}     -> Logger.info(inspect(event))
    #   {:error, reason} -> {:error, reason}
    # end

    {:ok, %{currency_pair: currency_pair, order_book: order_book, subscriber: subscriber}}
  end

  @doc false
  def terminate(_reason, %{order_book: order_book} = _state) do
    :ok = OrderBookAgent.stop(order_book)
  end

  # Server (callbacks)

  @doc false
  def handle_call(:clean_order_book, _from, %{order_book: agent} = state) do
    {:reply, OrderBookAgent.delete_all_objects(agent), state}
  end

  @doc false
  def handle_call(:order_book, _from, %{order_book: agent} = state) do
    {:reply, agent, state}
  end

  @doc false
  def handle_call(:fetch_order_book, _from, %{currency_pair: currency_pair, order_book: agent} = state) do
    {:reply, fetch_order_book(agent, [currencyPair: currency_pair, depth: 1]), state}
  end

  @doc false
  def handle_call({:fetch_order_book, [depth: depth]} = _msg, _from, %{currency_pair: currency_pair, order_book: agent} = state) do
    {:reply, fetch_order_book(agent, [currencyPair: currency_pair, depth: depth]), state}
  end

  @doc false
  def handle_call(:unsubscribe, _from, %{subscriber: subscriber, subscription: subscription} = state) do
    {:reply, WAMP.unsubscribe(subscriber, subscription), state}
  end

  @doc false
  def handle_call(:subscribe, _from, %{currency_pair: currency_pair, subscriber: subscriber} = state) do
    {:ok, subscription} = WAMP.subscribe(subscriber, currency_pair)
    {:reply, :ok, Map.put(state, :subscription, subscription)}
  end

  # Client API

  @doc false
  defp fetch_order_book(agent, params) do
    {:ok, 200, %{asks: asks, bids: bids, isFrozen: "0"}} = HTTP.return_order_book(params)
    fetch_order_book(agent, asks, bids)
  end


  import Krasukha.HTTP.PublicAPI, only: [to_tuple_with_floats: 1, to_float: 1]

  @doc false
  def fetch_order_book(agent, asks, bids) do
    [asks_book_tid, bids_book_tid] = OrderBookAgent.book_tids(agent)
    flow = [{asks, asks_book_tid}, {bids, bids_book_tid}]
    Enum.each(flow, fn({records, tid}) ->
      objects = Enum.map(records, fn(record) ->
        object = to_tuple_with_floats(record)
        object
      end)
      :true = :ets.insert(tid, objects)
    end)
    :ok
  end

  @doc false
  def update_order_book(agent, [_, _, _, data, _seq]) when is_list(data) do
    Enum.each(data, fn(action) -> update_order_book(agent, action) end)
    :ok
  end

  @doc false
  def update_order_book(agent, %{"data" => data, "type" => "orderBookModify"}) do
    tid = OrderBookAgent.book_tid(agent, data["type"])
    object = to_tuple_with_floats(data)
    :true = :ets.insert(tid, object)
  end

  @doc false
  def update_order_book(agent, %{"data" => data, "type" => "orderBookRemove"}) do
    tid = OrderBookAgent.book_tid(agent, data["type"])
    key = to_float(data["rate"])
    :true = :ets.delete(tid, key)
  end

  @doc false
  def update_order_book(agent, %{"data" => data, "type" => "newTrade"}) do
    tid = OrderBookAgent.book_tid(agent, data["type"])
    case :ets.lookup(tid, to_float(data["rate"])) do
      [{rate, amount}] ->
        object = {rate, (amount - to_float(data["amount"]))}
        :true = :ets.insert(tid, object)
      [] -> :ok #do nothing
    end
  end
end
