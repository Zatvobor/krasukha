defmodule Krasukha.LendingGen do
  @moduledoc false

  use GenServer

  import Krasukha.Helpers.String
  alias Krasukha.{HTTP}


  @doc false
  def start_link(currency) when is_binary(currency) do
    options = [name: to_name(currency, :lending)]
    GenServer.start_link(__MODULE__, [currency], options)
  end

  @doc false
  def init([currency]) do
    state = %{}
      |> Map.merge(%{currency: currency})
      |> Map.merge(__create_loan_orders_tables(currency))

    {:ok, state}
  end

  @doc false
  def __create_loan_orders_tables(currency \\ "untitled") do
    opts = [:ordered_set, :protected, :named_table, {:read_concurrency, true}]
    offers_tid  = :ets.new(to_name(currency, :loan_offers), opts)
    demands_tid = :ets.new(to_name(currency, :loan_demands), opts)
    %{orders_tids: %{offers_tid: offers_tid, demands_tid: demands_tid}}
  end

  # Server (callbacks)

  @doc false
  def handle_call(:orders_tids, _from, %{orders_tids: %{offers_tid: offers_tid, demands_tid: demands_tid}} = state) do
    {:reply, [offers_tid, demands_tid], state}
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
  def handle_call({:update_loan_orders, [every: seconds]}, _from, state) do
    fetcher = spawn(__MODULE__, :loan_offers_fetcher, [self, seconds * 1000])
    {:reply, :ok, Map.put(state, :fetcher, fetcher)}
  end

  @doc false
  def handle_call(:stop_to_update_loan_orders, _from, %{fetcher: fetcher} = state) do
    Process.exit(fetcher, :normal)
    {:reply, :ok, Map.delete(state, :fetcher)}
  end

  @doc false
  def loan_offers_fetcher(server, timeout) when is_pid(server) do
    ref = Process.monitor(server)
    loan_offers_fetcher(ref, server, timeout)
    :true = Process.demonitor(ref)
  end

  def loan_offers_fetcher(ref, server, timeout) when is_reference(ref) do
    Process.flag(:trap_exit, true)
    receive do
      {:DOWN, ^ref, _, _, _}   -> :ok
      {:EXIT, ^server, :normal} -> :ok
    after
      timeout ->
        :ok = GenServer.call(server, :fetch_loan_orders)
        loan_offers_fetcher(ref, server, timeout)
    end
  end


  # Client API

  def fetch_loan_orders(%{currency: currency} = state) do
    {:ok, 200, %{offers: offers, demands: demands}} = HTTP.PublicAPI.return_loan_orders(currency)
    fetch_loan_orders(state, offers, demands)
  end

  def fetch_loan_orders(%{orders_tids: %{offers_tid: offers_tid, demands_tid: demands_tid}}, offers, demands) do
    flow = [{offers_tid, offers}, {demands_tid, demands}]
    Enum.each(flow, fn({tid, records}) ->
      objects = Enum.map(records, fn(record) ->
        {rate, amount} = to_tuple_with_floats(record)
        {rate, amount, record.rangeMax, record.rangeMin}
      end)
      :true = :ets.insert(tid, objects)
    end)
    :ok
  end
end
