defmodule Krasukha.LendingRoutines do
  @moduledoc false

  alias Krasukha.{SecretAgent, Helpers.Naming, HTTP.PrivateAPI}


  @doc false
  def start_link(agent, strategy, params) do
    pid = start_routine(agent, strategy, params)
    {:ok, pid}
  end

  @doc false
  def start_routine(agent, strategy, %{currency: currency} = params) do
    # initial state starts w/ default params
    state = %{fetch_loan_orders: false, sleep_time_inactive: 60, gap_top_position: 10}
      |> Map.merge(params)
      |> Map.merge(%{currency_lending: Naming.process_name(currency, :lending)})
      |> Map.merge(%{agent: agent})

    spawn_link(__MODULE__, strategy, [state])
  end


  @doc false
  def available_balance_to_top_gap_top_position(%{sleep_time_inactive: sleep_time_inactive} = params) do
    Process.flag(:trap_exit, true)
    receive do
      {:EXIT, _, :normal} -> :ok
    after
      sleep_time_inactive * 1000 ->
        {rate, amount, _, _} = find_offer_object(params)
        rate = float_to_binary(rate)
        balance = get_account_balance(params)
        cond do
          is_binary(balance) ->
            create_loan_offer(rate, balance, params)
          balance == nil ->
            :ok
        end
        available_balance_to_top_gap_top_position(params)
    end
  end

  @doc false
  def find_offer_object(%{gap_top_position: gap_top_position, currency_lending: currency_lending, fetch_loan_orders: fetch_loan_orders}) do
    if fetch_loan_orders do
      GenServer.call(currency_lending, :fetch_loan_orders)
    end
    offers_tid = GenServer.call(currency_lending, :offers_tid)
    [object] = :ets.slot(offers_tid, gap_top_position)
    object
  end

  @doc false
  def get_account_balance(%{agent: agent, currency: currency}) do
    balance = SecretAgent.account_balance!(agent, :lending)[String.to_atom(currency)]
    if balance, do: float_to_binary(balance)
  end

  @doc false
  def create_loan_offer(rate, amount, %{agent: agent, currency: currency}) do
    params = [currency: currency, lendingRate: rate, amount: amount, duration: 2, autoRenew: 0]
    {:ok, 200, _} = PrivateAPI.create_loan_offer(agent, params)
    # %{message: "Loan order placed.", orderID: 136543484, success: 1}
  end

  defp float_to_binary(float), do: :erlang.float_to_binary(float, [{:decimals, 8}])
end
