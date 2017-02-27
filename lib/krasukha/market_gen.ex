alias Krasukha.{HTTP, WAMP, Helpers}

defmodule Krasukha.MarketGen do
  use GenServer

  @moduledoc false

  @doc false
  def start_link(currency_pair, preflight_opts \\ []) when is_binary(currency_pair) do
    options = [name: Helpers.Naming.process_name(currency_pair, :market)]
    GenServer.start_link(__MODULE__, [currency_pair, preflight_opts], options)
  end

  @doc false
  def default_params() do
    %{}
      |> Map.merge(%{order_book_depth: :infinity})
  end

  @doc false
  def init([currency_pair, preflight_opts]) do
    %{subscriber: subscriber} = WAMP.connection()

    state = default_params()
      |> Map.merge(%{currency_pair: currency_pair, subscriber: subscriber})
      |> Map.merge(__create_books_table(currency_pair))
      |> Map.merge(__create_history_table(currency_pair))

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

  @doc false
  def __create_gen_event() do
    {:ok, event_manager} = GenEvent.start_link()
    %{event_manager: event_manager}
  end


  # Server (callbacks)

  @doc false
  def handle_call(:create_event_manager, _from, state) do
    new_state = create_event_manager(state)
    {:reply, new_state.event_manager, new_state}
  end
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
  def handle_call(:clean_order_book, _from, state) do
    new_state = clean_order_book(state)
    {:reply, :ok, new_state}
  end

  @doc false
  def handle_call({:order_book_depth, depth}, _from, state) do
    {:reply, :ok, %{state | order_book_depth: depth}}
  end

  @doc false
  def handle_call(:fetch_order_book, _from, %{currency_pair: currency_pair} = state) do
    new_state = fetch_order_book(state, [currencyPair: currency_pair, depth: 1])
    {:reply, new_state.fetch_order_book_result, new_state}
  end

  @doc false
  def handle_call({:fetch_order_book, [depth: depth]}, _from, %{currency_pair: currency_pair} = state) do
    new_state = fetch_order_book(state, [currencyPair: currency_pair, depth: depth])
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
  def handle_info({_module, _from, %{args: args}}, %{order_book_depth: :infinity} = state) do
    :ok = update_order_book(state, args)
    {:noreply, state}
  end

  @doc false
  def handle_info({_module, _from, %{args: args}}, %{order_book_depth: depth, book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}} = state) do
    cond do
      :ets.info(asks_book_tid, :size) > depth -> clean_order_book(asks_book_tid)
      :ets.info(bids_book_tid, :size) > depth -> clean_order_book(bids_book_tid)
      true -> :ok #do_nothing
    end
    :ok = update_order_book(state, args)
    {:noreply, state}
  end

  @doc false
  defdelegate handle_info(suspend_or_resume, state), to: Helpers.Gen

  @doc false
  def terminate(_reason, state) do
    with subscription when is_integer(subscription) <- state[:subscription], do: unsubscribe(state)
  end


  # Client API

  import Helpers.String, only: [to_atom: 1, to_float: 1, to_tuple_with_floats: 1]

  @doc false
  def create_event_manager(state) do
    {:ok, event_manager} = GenEvent.start_link()
    Map.merge(state, %{event_manager: event_manager})
  end

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
  def fetch_order_book(state, params) do
    {:ok, 200, %{asks: asks, bids: bids, isFrozen: "0"}} = HTTP.PublicAPI.return_order_book(params)
    result = fetch_order_book(state, asks, bids)
    Map.put(state, :fetch_order_book_result, result)
  end

  @doc false
  def fetch_order_book(%{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}} = state, asks, bids) do
    flow = [{asks, asks_book_tid}, {bids, bids_book_tid}]
    for {records, tid} <- flow do
      objects = Enum.map(records, fn(record) -> to_tuple_with_floats(record) end)
      :ok = notify(state, {:fetch_order_book, objects})
      :true = :ets.insert(tid, objects)
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
    object = to_tuple_with_floats(data)
    :ok = notify(state, {:update_order_book, :orderBookModify, object})
    :true = book_tid(state, data["type"])
      |> :ets.insert(object)
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "orderBookRemove"}) do
    key = to_float(data["rate"])
    object = to_tuple_with_floats(data)
    :ok = notify(state, {:update_order_book, :orderBookRemove, object})
    :true = book_tid(state, data["type"])
      |> :ets.delete(key)
  end

  @doc false
  def update_order_book(state, %{"data" => data, "type" => "newTrade"}) do
    object = {data["date"], to_atom(data["type"]), to_float(data["rate"]), to_float(data["amount"]), to_float(data["total"]), data["tradeID"]}
    :ok = notify(state, {:update_order_history, object})
    :true = history_tid(state)
      |> :ets.insert(object)
  end

  @doc false
  def clean_order_book(%{book_tids: %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid}, history_tid: history_tid} = state) do
    for tid <- [asks_book_tid, bids_book_tid, history_tid], do: :true = clean_order_book(tid)
    state
  end
  def clean_order_book(tid) when is_atom(tid), do: :ets.delete_all_objects(tid)

  defp book_tid(%{book_tids: %{asks_book_tid: asks_book_tid}}, type) when type in [:asks, "ask", "buy"], do: asks_book_tid
  defp book_tid(%{book_tids: %{bids_book_tid: bids_book_tid}}, type) when type in [:bids, "bid", "sell"], do: bids_book_tid
  defp history_tid(%{history_tid: history_tid}), do: history_tid
  defp notify(%{event_manager: event_manager}, event), do: GenEvent.notify(event_manager, event)
  defp notify(%{}, _event), do: :ok
end
