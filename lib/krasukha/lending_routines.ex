alias Krasukha.{HTTP, Helpers.Naming, Helpers.Routine, Helpers.String}

defmodule Krasukha.LendingRoutines do
  @moduledoc false

  @doc false
  def start_link(agent, strategy, params) do
    pid = start(agent, strategy, params)
    :true = Process.link(pid)
    {:ok, pid}
  end

  @doc false
  def start(agent, strategy, params) do
    state = init(agent, params)
    spawn(Routine, :start_routine, [__MODULE__, strategy, state])
  end

  @doc false
  def default_params() do
    Routine.default_params()
      # known options for strategies like `available_balance_to_gap_position`
      |> Map.merge(%{duration: 2, auto_renew: 0, gap_top_position: 10}) # gap_bottom_position
      |> Map.merge(%{fetch_loan_orders: false})
      # known options for strategy `cancel_open_loan_offers`
      |> Map.merge(%{after_time_inactive: 14400}) # in seconds (4 hours)
  end

  @doc false
  def init(agent, %{currency: currency} = params) do
    default_params()
      |> Map.merge(params)
      |> Map.merge(%{currency_lending: Naming.process_name(currency, :lending)})
      |> Map.merge(%{agent: agent})
  end

  @doc false
  def cancel_open_loan_offers(%{agent: agent, currency: currency} = params) do
    {:ok, 200, open_loan_offers} = HTTP.PrivateAPI.return_open_loan_offers(agent)
    open_loan_offers = open_loan_offers[String.to_atom(currency)]
    for open_loan_offer <- filter_open_loan_offers(open_loan_offers, params) do
      {:ok, 200, _} = HTTP.PrivateAPI.cancel_loan_offer(agent, [orderNumber: open_loan_offer.id])
      # %{success: 1, message: "Loan offer canceled."}
    end
  end

  @doc false
  def filter_open_loan_offers(nil, _params), do: []
  def filter_open_loan_offers(open_loan_offers, %{after_time_inactive: after_time_inactive}) do
    for open_loan_offer <- open_loan_offers do
      created_at_unix_time = String.to_erl_datetime(open_loan_offer.date)
        |> String.to_unix_time
      current_unix_time = String.now_to_erl_datetime()
        |> String.to_unix_time
      if (current_unix_time - created_at_unix_time) >= after_time_inactive do
        open_loan_offer
      end
    end
    |> Enum.reject(&(is_nil(&1))) # compact
  end

  @doc false
  def available_balance_to_gap_position(params) do
    balance = Routine.get_account_balance(params, :lending)
    if is_binary(balance) do
      {rate, _, _, _} = find_offer_object(params)
      rate = String.float_to_binary(rate)
      create_loan_offer(rate, balance, params)
    end
  end

  @doc false
  def find_offer_object(%{gap_top_position: gap_top_position} = params) do
    fetch_loan_orders(params)
    offers_tid = offers_tid(params)
    lookup(offers_tid, :next, gap_top_position, :ets.first(offers_tid))
  end

  @doc false
  def find_offer_object(%{gap_bottom_position: gap_bottom_position} = params) do
    fetch_loan_orders(params)
    offers_tid = offers_tid(params)
    lookup(offers_tid, :prev, gap_bottom_position, :ets.last(offers_tid))
  end

  defp lookup(tid, direction, position, key, i \\ 1) do
    case i do
      ^position ->
        :ets.lookup(tid, key)
          |> List.first
      _ ->
        next = apply(:ets, direction, [tid, key])
        step = if(next == :"$end_of_table", do: key, else: next)
        lookup(tid, direction, position, step, i + 1)
    end
  end

  defp fetch_loan_orders(%{fetch_loan_orders: true, currency_lending: currency_lending}) do
    :ok = GenServer.call(currency_lending, :clean_loan_orders)
    :ok = GenServer.call(currency_lending, :fetch_loan_orders)
    :ok
  end
  defp fetch_loan_orders(%{fetch_loan_orders: false, currency_lending: _}), do: :false

  defp offers_tid(%{currency_lending: currency_lending}) do
    GenServer.call(currency_lending, :offers_tid)
  end

  @doc false
  def create_loan_offer(rate, amount, %{agent: agent, currency: currency, duration: duration, auto_renew: auto_renew}) do
    params = [currency: currency, lendingRate: rate, amount: amount, duration: duration, autoRenew: auto_renew]
    {:ok, 200, _} = HTTP.PrivateAPI.create_loan_offer(agent, params)
    # %{message: "Loan order placed.", orderID: 136543484, success: 1}
  end
end
