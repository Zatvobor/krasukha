alias Krasukha.{HTTP, WAMP, Helpers}

defmodule Krasukha.MarketGen do
  use GenServer
  use Krasukha.Helpers.EventGen

  @moduledoc false

  @doc false
  def start_link(params, preflight_opts \\ [])
  def start_link(currency_pair, preflight_opts) when is_binary(currency_pair) do
    start_link(%{currency_pair: currency_pair}, preflight_opts)
  end
  def start_link(%{currency_pair: currency_pair} = params, preflight_opts) when is_map(params) do
    options = [name: Helpers.Naming.process_name(currency_pair, :market)]
    GenServer.start_link(__MODULE__, [params, preflight_opts], options)
  end

  @doc false
  def default_params() do
    %{}
      |> Map.merge(%{order_book_depth: :infinity})
  end

  @doc false
  def init([params, preflight_opts]) do
    params = Map.merge(default_params(), params)
    state = params
      |> Map.merge(WAMP.connection())
      |> Map.merge(__create_books_table(params.currency_pair))
      |> Map.merge(__create_history_table(params.currency_pair))

    # applies preflight setup
    state = apply_preflight_opts(state, preflight_opts, __MODULE__)

    {:ok, state}
  end

  @doc false
  defdelegate apply_preflight_opts(state, preflight_opts, mod), to: Helpers.Gen

  @doc false
  def __create_books_table(currency_pair \\ "untitled") do
    opts = [:ordered_set, :protected, :named_table, {:read_concurrency, true}]
    asks_book_tid = :ets.new(Helpers.Naming.to_name(currency_pair, :asks), opts)
    bids_book_tid = :ets.new(Helpers.Naming.to_name(currency_pair, :bids), opts)
    %{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}}
  end

  @doc false
  def __create_history_table(currency_pair \\ "untitled") do
    opts = [:set, :protected, :named_table, {:read_concurrency, true}]
    history_tid = :ets.new(Helpers.Naming.to_name(currency_pair, :history), opts)
    %{history_tid: history_tid}
  end


  # Server (callbacks)

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
  def handle_call(:clean_order_books, _from, state) do
    :ok = clean_order_books(state)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call(:clean_history_book, _from, %{history_tid: history_tid} = state) do
    :ok = clean_order_book(history_tid)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call({:order_book_depth, depth}, _from, state) do
    {:reply, :ok, %{state | order_book_depth: depth}}
  end

  @doc false
  def handle_call(:order_book_depth, _from, %{order_book_depth: order_book_depth} = state) do
    {:reply, order_book_depth, state}
  end

  @doc false
  def handle_call({:fetch_order_books, [depth: depth]}, _from, %{currency_pair: currency_pair} = state) do
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: depth])
    {:reply, new_state.fetch_order_book_result, new_state}
  end

  @doc false
  def handle_call(:fetch_order_books, _from, %{currency_pair: currency_pair} = state) do
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: 1])
    {:reply, new_state.fetch_order_book_result, new_state}
  end

  @doc false
  def handle_call(:unsubscribe, _from, state) do
    new_state = unsubscribe(state)
    {:reply, new_state.unsubscribed, new_state}
  end

  @doc false
  def handle_call(:subscribe, _from, state) do
    new_state = subscribe(state)
    {:reply, {:ok, new_state.subscription},  new_state}
  end

  @doc false
  def handle_call({:shrink_order_books, depth}, _from, %{currency_pair: currency_pair} = state) do
    :ok = clean_order_books(state)
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: depth])
    {:reply, :ok, new_state}
  end

  @doc false
  def handle_call(:shrink_order_books, %{currency_pair: currency_pair, order_book_depth: order_book_depth} = state) when is_integer(order_book_depth) do
    :ok = clean_order_books(state)
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: order_book_depth])
    {:reply, :ok, new_state}
  end

  @doc false
  def handle_info({_module, _from, %{args: args}}, state) do
    :ok = update_order_book(state, args)
    {:noreply, state}
  end

  @doc false
  def handle_info(:clean_order_books, state) do
    :ok = clean_order_books(state)
    {:noreply, state}
  end

  @doc false
  def handle_info(:clean_history_book, %{history_tid: history_tid} = state) do
    :ok = clean_order_book(history_tid)
    {:noreply, state}
  end

  @doc false
  def handle_info(:fetch_order_books, %{currency_pair: currency_pair} = state) do
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: 1])
    {:noreply, new_state}
  end

  @doc false
  def handle_info({:fetch_order_books, depth}, %{currency_pair: currency_pair} = state) do
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: depth])
    {:noreply, new_state}
  end

  @doc false
  def handle_info(:unsubscribe, state) do
    new_state = unsubscribe(state)
    {:noreply, new_state}
  end

  @doc false
  def handle_info(:subscribe, state) do
    new_state = subscribe(state)
    {:noreply, new_state}
  end

  @doc false
  def handle_info(:shrink_order_books, %{currency_pair: currency_pair, order_book_depth: order_book_depth} = state) when is_integer(order_book_depth) do
    :ok = clean_order_books(state)
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: order_book_depth])
    {:noreply, new_state}
  end

  @doc false
  def handle_info({:shrink_order_books, order_book_depth}, %{currency_pair: currency_pair} = state) do
    :ok = clean_order_books(state)
    new_state = fetch_order_books(state, [currencyPair: currency_pair, depth: order_book_depth])
    {:noreply, new_state}
  end

  @doc false
  defdelegate handle_info(suspend_or_resume, state), to: Helpers.Gen

  @doc false
  def terminate(_reason, state) do
    with subscription when is_integer(subscription) <- state[:subscription], do: unsubscribe(state)
  end


  # Client API

  import Helpers.String, only: [to_atom: 1, to_float: 1, to_tuple_with_floats: 1, to_integer: 1]

  @doc false
  def subscribe(%{currency_pair: currency_pair, subscriber: subscriber} = state) do
    {:ok, subscription} = WAMP.subscribe(subscriber, currency_pair)
    Map.put(state, :subscription, subscription)
    |> Map.delete(:unsubscribed)
  end

  @doc false
  def unsubscribe(%{subscriber: subscriber, subscription: subscription} = state) do
    unsubscribed = WAMP.unsubscribe(subscriber, subscription)
    Map.delete(state, :subscription)
    |> Map.put(:unsubscribed, unsubscribed)
  end

  @doc false
  def fetch_order_books(state, params) do
    {:ok, 200, %{asks: asks, bids: bids, isFrozen: "0"}} = HTTP.PublicAPI.return_order_book(params)
    result = fetch_order_books(state, asks, bids)
    Map.put(state, :fetch_order_book_result, result)
  end

  @doc false
  def fetch_order_books(%{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}} = state, asks, bids) do
    flow = [{asks, asks_book_tid}, {bids, bids_book_tid}]
    for {records, tid} <- flow do
      objects = Enum.map(records, fn(record) -> to_tuple_with_floats(record) end)
      :true = :ets.insert(tid, objects)
      :ok = notify(state, {:fetch_order_book, objects})
    end
    :ok
  end

  @doc false
  def update_order_book(state, [_, _, _, data, _seq]) when is_list(data) do
    for action <- data, do: update_order_book(state, action)
    :ok
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "orderBookModify"}) do
    tid = book_tid(state, data["type"])
    object = to_tuple_with_floats(data)
    :true = :ets.insert(tid, object)
    :ok = notify(state, {:update_order_book, :orderBookModify, object})
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "orderBookRemove"}) do
    key = to_float(data["rate"])
    tid = book_tid(state, data["type"])
    object = to_tuple_with_floats(data)
    :true = :ets.delete(tid, key)
    :ok = notify(state, {:update_order_book, :orderBookRemove, object})
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "newTrade"}) do
    tid = history_tid(state)
    object = {to_integer(data["tradeID"]), data["date"], to_atom(data["type"]), to_float(data["rate"]), to_float(data["amount"]), to_float(data["total"])}
    :true = :ets.insert(tid, object)
    :ok = notify(state, {:update_order_history, object})
  end

  @doc false
  def clean_order_book(%{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}, history_tid: history_tid} = state) do
    for tid <- [asks_book_tid, bids_book_tid, history_tid], do: :true = clean_order_book(tid)
    state
  end
  def clean_order_book(tid) when is_atom(tid) do
    :true = :ets.delete_all_objects(tid)
    :ok
  end

  @doc false
  def clean_order_books(%{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}} = _state) do
    for tid <- [asks_book_tid, bids_book_tid], do: :ok = clean_order_book(tid)
    :ok
  end

  defp book_tid(%{book_tids: %{asks_book_tid: asks_book_tid}}, type) when type in [:asks, "ask", "buy"], do: asks_book_tid
  defp book_tid(%{book_tids: %{bids_book_tid: bids_book_tid}}, type) when type in [:bids, "bid", "sell"], do: bids_book_tid
  defp history_tid(%{history_tid: history_tid}), do: history_tid
end
