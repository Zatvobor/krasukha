defmodule Krasukha.MarketGen do
  @moduledoc false

  use GenServer

  import String, only: [to_atom: 1]

  alias Krasukha.{HTTP, WAMP}


  @doc false
  def start_link(currency_pair) when is_binary(currency_pair) do
    options = [name: to_name(currency_pair, :market)]
    GenServer.start_link(__MODULE__, [currency_pair], options)
  end

  @doc false
  def init([currency_pair]) do
    %{subscriber: subscriber} = WAMP.connection()

    state = %{}
      |> Map.merge(%{currency_pair: currency_pair, subscriber: subscriber})
      |> Map.merge(__create_books_table(currency_pair))
      |> Map.merge(__create_history_table(currency_pair))
      |> Map.merge(__create_gen_event())

    {:ok, state}
  end

  @doc false
  def __create_books_table(currency_pair \\ "untitled") do
    opts = [:ordered_set, :protected, :named_table, {:read_concurrency, true}]
    asks_book_tid = :ets.new(to_name(currency_pair, :asks), opts)
    bids_book_tid = :ets.new(to_name(currency_pair, :bids), opts)
    %{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}}
  end

  @doc false
  def __create_history_table(currency_pair \\ "untitled") do
    opts = [:set, :protected, :named_table, {:read_concurrency, true}]
    history_tid = :ets.new(to_name(currency_pair, :history), opts)
    %{history_tid: history_tid}
  end

  @doc false
  def __create_gen_event() do
    {:ok, event_manager} = GenEvent.start_link()
    %{event_manager: event_manager}
  end

  @doc false
  def to_name(prefix, type), do: to_atom("#{String.downcase(prefix)}_#{type}")

  # Server (callbacks)

  @doc false
  def handle_call(:event_manager, _from, %{event_manager: event_manager} = state) do
    {:reply, event_manager, state}
  end

  @doc false
  def handle_call(:tids, _from, %{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}, history_tid: history_tid} = state) do
    {:reply, [asks_book_tid, bids_book_tid, history_tid], state}
  end

  @doc false
  def handle_call(:book_tids, _from, %{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}} = state) do
    {:reply, [asks_book_tid, bids_book_tid], state}
  end

  @doc false
  def handle_call(:asks_book_tid, _from, %{book_tids: %{asks_book_tid: asks_book_tid}} = state) do
    {:reply, asks_book_tid, state}
  end

  @doc false
  def handle_call(:bids_book_tid, _from, %{book_tids: %{bids_book_tid: bids_book_tid}} = state) do
    {:reply, bids_book_tid, state}
  end

  @doc false
  def handle_call({:book_tid, type}, _from, %{book_tids: %{asks_book_tid: asks_book_tid}} = state) when type in [:asks, "ask", "buy"] do
    {:reply, asks_book_tid, state}
  end

  @doc false
  def handle_call({:book_tid, type}, _from, %{book_tids: %{bids_book_tid: bids_book_tid}} = state) when type in [:bids, "bid", "sell"] do
    {:reply, bids_book_tid, state}
  end

  @doc false
  def handle_call(:history_tid, _from, %{history_tid: history_tid} = state) do
    {:reply, history_tid, state}
  end

  @doc false
  def handle_call(:clean_order_book, _from, %{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}, history_tid: history_tid} = state) do
    Enum.each([asks_book_tid, bids_book_tid, history_tid], fn(tid) -> :true = :ets.delete_all_objects(tid) end)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call(:fetch_order_book, _from, %{currency_pair: currency_pair} = state) do
    fetched = fetch_order_book(state, [currencyPair: currency_pair, depth: 1])
    {:reply, fetched, state}
  end

  @doc false
  def handle_call({:fetch_order_book, [depth: depth]}, _from, %{currency_pair: currency_pair} = state) do
    fetched = fetch_order_book(state, [currencyPair: currency_pair, depth: depth])
    {:reply, fetched, state}
  end

  @doc false
  def handle_call(:unsubscribe, _from, %{subscriber: subscriber, subscription: subscription} = state) do
    unsubscribed = WAMP.unsubscribe(subscriber, subscription)
    {:reply, unsubscribed, Map.delete(state, :subscription)}
  end

  @doc false
  def handle_call(:subscribe, _from, %{currency_pair: currency_pair, subscriber: subscriber} = state) do
    {:ok, subscription} = WAMP.subscribe(subscriber, currency_pair)
    {:reply, {:ok, subscription},  Map.put(state, :subscription, subscription)}
  end

  @doc false
  def handle_info({_module, _from, %{args: args}}, state) do
    :ok = update_order_book(state, args)
    {:noreply, state}
  end

  @doc false
  def terminate(_reason, state) do
    if state[:subscription], do: GenServer.call(self, :unsubscribe)
    :ok
  end


  # Client API

  @doc false
  defp fetch_order_book(state, params) do
    {:ok, 200, %{asks: asks, bids: bids, isFrozen: "0"}} = HTTP.return_order_book(params)
    fetch_order_book(state, asks, bids)
  end


  import Krasukha.HTTP.PublicAPI, only: [to_tuple_with_floats: 1, to_float: 1]

  @doc false
  def fetch_order_book(%{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}} = state, asks, bids) do
    flow = [{asks, asks_book_tid}, {bids, bids_book_tid}]
    Enum.each(flow, fn({records, tid}) ->
      objects = Enum.map(records, fn(record) -> to_tuple_with_floats(record) end)
      :ok = notify(state, {:fetch_order_book, objects})
      :true = :ets.insert(tid, objects)
    end)
    :ok
  end

  @doc false
  def update_order_book(state, [_, _, _, data, _seq]) when is_list(data) do
    Enum.each(data, fn(action) -> update_order_book(state, action) end)
    :ok
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "orderBookModify"}) do
    tid = book_tid(state, data["type"])
    object = to_tuple_with_floats(data)
    :ok = notify(state, {:update_order_book, :orderBookModify, object})
    :true = :ets.insert(tid, object)
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "orderBookRemove"}) do
    tid = book_tid(state, data["type"])
    key = to_float(data["rate"])
    object = to_tuple_with_floats(data)
    :ok = notify(state, {:update_order_book, :orderBookRemove, object})
    :true = :ets.delete(tid, key)
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "newTrade"}) do
    # update order book
    tid = book_tid(state, data["type"])
    case :ets.lookup(tid, to_float(data["rate"])) do
      [{rate, amount}] ->
        object = {rate, (amount - to_float(data["amount"]))}
        :ok = notify(state, {:update_order_book, :newTrade, object})
        :true = :ets.insert(tid, object)
      [] -> :ok #do nothing
    end
    # update trading history
    tid = history_tid(state)
    object = {data["date"], to_atom(data["type"]), to_float(data["rate"]), to_float(data["amount"]), to_float(data["total"]), data["tradeID"]}
    :ok = notify(state, {:update_order_history, object})
    :true = :ets.insert(tid, object)
  end

  defp book_tid(%{book_tids: %{asks_book_tid: asks_book_tid}}, type) when type in [:asks, "ask", "buy"], do: asks_book_tid
  defp book_tid(%{book_tids: %{bids_book_tid: bids_book_tid}}, type) when type in [:bids, "bid", "sell"], do: bids_book_tid
  defp history_tid(%{history_tid: history_tid}), do: history_tid
  defp notify(%{event_manager: event_manager}, event), do: GenEvent.notify(event_manager, event)
  defp notify(%{}, _event), do: :ok
end
