require Logger
alias Krasukha.{HTTP, Helpers}

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
    :proc_lib.spawn(Helpers.Routine, :start_routine, [self(), __MODULE__, strategy, state])
  end

  @doc false
  def default_params() do
    Helpers.Routine.default_params()
      # known options for strategies like `available_balance_to_gap_position`
      |> Map.merge(%{duration: 2, auto_renew: 0, gap_top_position: 10}) # gap_bottom_position
      |> Map.merge(%{fetch_loan_orders: false})
      |> Map.merge(%{stop_rate: :infinity})
      # known options for strategy `cancel_open_loan_offers`
      |> Map.merge(%{after_time_inactive: 14400}) # in seconds (4 hours)
  end

  @doc false
  def init(agent, %{currency: currency} = params) do
    params = Map.merge(default_params(), params)
    params
      |> Map.merge(%{currency_lending: Helpers.Naming.process_name(currency, :lending)})
      |> Map.merge(%{stop_rate: nz(params.stop_rate)})
      |> Map.merge(%{agent: agent})
  end

  defdelegate nz(field), to: Helpers.Routine

  @doc false
  defdelegate do_nothing(state), to: Helpers.Routine

  @doc false
  def cancel_open_loan_offers(%{agent: agent, currency: currency} = params) do
    {:ok, 200, open_loan_offers} = HTTP.PrivateAPI.return_open_loan_offers(agent)
    open_loan_offers = open_loan_offers[Helpers.String.to_atom(currency)]
    for open_loan_offer <- filter_open_loan_offers(open_loan_offers, params) do
      {:ok, 200, response} = HTTP.PrivateAPI.cancel_loan_offer(agent, [orderNumber: open_loan_offer.id])
      # %{success: 1, message: "Loan offer canceled."}
      response |> inspect |> Logger.info
    end
  end

  @doc false
  def filter_open_loan_offers(nil, _params), do: []
  def filter_open_loan_offers(open_loan_offers, %{after_time_inactive: after_time_inactive}) do
    for open_loan_offer <- open_loan_offers do
      created_at_unix_time = Helpers.String.to_erl_datetime(open_loan_offer.date)
        |> Helpers.String.to_unix_time
      current_unix_time = Helpers.String.now_to_erl_datetime()
        |> Helpers.String.to_unix_time
      if (current_unix_time - created_at_unix_time) >= after_time_inactive do
        open_loan_offer
      end
    end
    |> Enum.reject(&(is_nil(&1))) # compact
  end

  @doc false
  def available_balance_to_gap_position(%{agent: agent, currency: currency, stop_rate: stop_rate} = params) do
    with balance when is_number(balance) <- Krasukha.SecretAgent.account_balance!(agent, :lending, currency) do
      {rate, _, _, _} = find_offer_object(params)
      cond do
        stop_rate == :infinity ->
          create_loan_offer(rate, balance, params)
        rate > stop_rate ->
          create_loan_offer(rate, balance, params)
        true -> :ok
      end
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
    params = [currency: currency, lendingRate: Helpers.String.float_to_binary(rate), amount: Helpers.String.float_to_binary(amount), duration: duration, autoRenew: auto_renew]
    {:ok, 200, response} = HTTP.PrivateAPI.create_loan_offer(agent, params)
    response |> inspect |> Logger.info
  end
end
