alias Krasukha.{HTTP, Helpers}

defmodule Krasukha.LendingGen do
  use GenServer

  @moduledoc false

  @doc false
  def start_link(currency, preflight_opts \\ []) when is_binary(currency) do
    options = [name: Helpers.Naming.process_name(currency, :lending)]
    GenServer.start_link(__MODULE__, [currency, preflight_opts], options)
  end

  @doc false
  def init([currency, preflight_opts]) do
    state = %{}
      |> Map.merge(%{currency: currency})
      |> Map.merge(__create_loan_orders_tables(currency))

    # applies preflight setup
    state = apply_preflight_opts(state, preflight_opts)

    {:ok, state}
  end

  @doc false
  defp apply_preflight_opts(state, []), do: state
  defp apply_preflight_opts(state, [h | t]) do
    new_state = case h do
      {function, args} when is_atom(function) -> apply(__MODULE__, function, [state, args])
      function when is_atom(function) -> apply(__MODULE__, function, [state])
    end
    apply_preflight_opts(new_state, t)
  end

  @doc false
  def __create_loan_orders_tables(currency \\ "untitled") do
    offers_tid  = :ets.new(Helpers.Naming.to_name(currency, :loan_offers), __loan_orders_table_access)
    demands_tid = :ets.new(Helpers.Naming.to_name(currency, :loan_demands), __loan_orders_table_access)
    %{orders_tids: %{offers_tid: offers_tid, demands_tid: demands_tid}}
  end

  @doc false
  def __loan_orders_table_access() do
    access = if(Mix.env == :test, do: :public, else: :protected)
    [:ordered_set, access, :named_table, {:read_concurrency, true}]
  end

  # Server (callbacks)

  @doc false
  def handle_call(:orders_tids, _from, %{orders_tids: %{offers_tid: offers_tid, demands_tid: demands_tid}} = state) do
    {:reply, [offers_tid, demands_tid], state}
  end

  @doc false
  def handle_call({:orders_tids, orders_tids}, _from, state) do
    {:reply, :ok, %{state | orders_tids: orders_tids}}
  end

  @doc false
  def handle_call(:offers_tid, _from, %{orders_tids: %{offers_tid: offers_tid}} = state) do
    {:reply, offers_tid, state}
  end

  @doc false
  def handle_call(:clean_loan_offers, _from, %{orders_tids: %{offers_tid: offers_tid}} = state) do
    :true = :ets.delete_all_objects(offers_tid)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call(:demands_tid, _from, %{orders_tids: %{demands_tid: demands_tid}} = state) do
    {:reply, demands_tid, state}
  end

  @doc false
  def handle_call(:clean_loan_demands, _from, %{orders_tids: %{demands_tid: demands_tid}} = state) do
    :true = :ets.delete_all_objects(demands_tid)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call(:clean_loan_orders, _from, %{orders_tids: %{offers_tid: offers_tid, demands_tid: demands_tid}} = state) do
    Enum.each([offers_tid, demands_tid], fn(tid) -> :true = :ets.delete_all_objects(tid) end)
    {:reply, :ok, state}
  end

  @doc false
  def handle_call(:fetch_loan_orders, _from, state) do
    fetched = fetch_loan_orders(state)
    {:reply, fetched, state}
  end

  @doc false
  def handle_call({:update_loan_orders, [every: _seconds] = params}, _from, state) do
    new_state = update_loan_orders(state, params)
    {:reply, new_state.fetcher, new_state}
  end

  @doc false
  def handle_call(:stop_to_update_loan_orders, _from, %{fetcher: fetcher} = state) do
    Process.exit(fetcher, :normal)
    {:reply, :ok, Map.delete(state, :fetcher)}
  end

  @doc false
  def loan_offers_fetcher(server, timeout) do
    ref = Process.monitor(server)
    Process.flag(:trap_exit, true)
    loan_offers_fetcher(ref, server, timeout)
    :true = Process.demonitor(ref)
  end

  def loan_offers_fetcher(ref, server, timeout) do
    GenServer.call(server, :fetch_loan_orders)
    receive do
      {:DOWN, ^ref, _, _, _}    -> :ok
      {:EXIT, ^server, :normal} -> :ok
    after
      timeout ->
        loan_offers_fetcher(ref, server, timeout)
    end
  end


  # Client API

  def update_loan_orders(state, [every: seconds]) do
    pid = spawn(__MODULE__, :loan_offers_fetcher, [self(), seconds * 1000])
    Map.merge(state, %{fetcher: pid})
  end

  def fetch_loan_orders(%{currency: currency} = state) do
    {:ok, 200, %{offers: offers, demands: demands}} = HTTP.PublicAPI.return_loan_orders(currency)
    fetch_loan_orders(state, offers, demands)
  end

  def fetch_loan_orders(%{orders_tids: %{offers_tid: offers_tid, demands_tid: demands_tid}}, offers, demands) do
    flow = [{offers_tid, offers}, {demands_tid, demands}]
    Enum.each(flow, fn({tid, records}) ->
      objects = Enum.map(records, fn(record) ->
        {rate, amount} = Helpers.String.to_tuple_with_floats(record)
        {rate, amount, record.rangeMax, record.rangeMin}
      end)
      :true = :ets.insert(tid, objects)
    end)
    :ok
  end
end
