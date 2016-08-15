defmodule Krasukha.LendingRoutines do
  @moduledoc false

  alias Krasukha.{SecretAgent, Helpers.Naming, HTTP.PrivateAPI}


  @doc false
  def start_link(agent, strategy, params) do
    pid = start(agent, strategy, params)
    :true = Process.link(pid)
    {:ok, pid}
  end

  @doc false
  def start(agent, strategy, %{currency: currency} = params) do
    # initial state starts w/ default params
    state = %{fulfill_immediately: false, fetch_loan_orders: false, sleep_time_inactive: 60, gap_top_position: 10}
      |> Map.merge(params)
      |> Map.merge(%{currency_lending: Naming.process_name(currency, :lending)})
      |> Map.merge(%{agent: agent})

    spawn(__MODULE__, :start_routine, [strategy, state])
  end

  @doc false
  def available_balance_to_gap_position(params) do
    balance = get_account_balance(params)
    if is_binary(balance) do
      {rate, _, _, _} = find_offer_object(params)
      rate = float_to_binary(rate)
      create_loan_offer(rate, balance, params)
    end
  end

  @doc false
  def start_routine(strategy, %{fulfill_immediately: fulfill_immediately} = params) do
    Process.flag(:trap_exit, true)
    if(fulfill_immediately, do: apply(__MODULE__, strategy, [params]))
    loop(strategy, params)
  end

  @doc false
  def loop(strategy, %{sleep_time_inactive: sleep_time_inactive} = params) do
    receive do
      {:EXIT, _, :normal} -> :ok
    after
      sleep_time_inactive * 1000 ->
        apply(__MODULE__, strategy, [params])
        loop(strategy, params)
    end
  end

  @doc false
  def find_offer_object(%{gap_top_position: gap_top_position, currency_lending: currency_lending, fetch_loan_orders: fetch_loan_orders}) do
    if(fetch_loan_orders, do: GenServer.call(currency_lending, :fetch_loan_orders))
    offers_tid = GenServer.call(currency_lending, :offers_tid)
    [object] = :ets.slot(offers_tid, gap_top_position)
    object
  end

  @doc false
  def get_account_balance(%{agent: agent, currency: currency}) do
    SecretAgent.account_balance!(agent, :lending)[String.to_atom(currency)]
      |> float_to_binary()
  end

  @doc false
  def create_loan_offer(rate, amount, %{agent: agent, currency: currency}) do
    params = [currency: currency, lendingRate: rate, amount: amount, duration: 2, autoRenew: 0]
    {:ok, 200, _} = PrivateAPI.create_loan_offer(agent, params)
    # %{message: "Loan order placed.", orderID: 136543484, success: 1}
  end

  defp float_to_binary(nil), do: nil
  defp float_to_binary(float), do: :erlang.float_to_binary(float, [{:decimals, 8}])
end
