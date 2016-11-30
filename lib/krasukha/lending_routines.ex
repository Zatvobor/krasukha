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
  def start(agent, strategy, params) do
    state = init(agent, params)
    spawn(__MODULE__, :start_routine, [strategy, state])
  end

  @doc false
  def default_params() do
    %{}
      |> Map.merge(%{duration: 2, auto_renew: 0})
      |> Map.merge(%{fetch_loan_orders: false, gap_top_position: 10})
      |> Map.merge(%{fulfill_immediately: false, sleep_time_inactive: 60, sleep_time_inactive_seed: 1})
  end

  @doc false
  def init(agent, %{currency: currency} = params) do
    default_params()
      |> Map.merge(params)
      |> Map.merge(%{currency_lending: Naming.process_name(currency, :lending)})
      |> Map.merge(%{agent: agent})
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
  def loop(strategy, params) do
    receive do
      {:EXIT, _, :normal} -> :ok
    after
      sleep_time_timeout(params) ->
        apply(__MODULE__, strategy, [params])
        loop(strategy, params)
    end
  end

  @doc false
  def sleep_time_timeout(%{sleep_time_inactive: sleep_time_inactive, sleep_time_inactive_seed: sleep_time_inactive_seed}) do
    :rand.uniform(sleep_time_inactive_seed) + (sleep_time_inactive * 1000) # in minutes
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

  defp fetch_loan_orders(%{fetch_loan_orders: fetch_loan_orders, currency_lending: currency_lending}) do
    if(fetch_loan_orders, do: GenServer.call(currency_lending, :fetch_loan_orders))
  end

  defp offers_tid(%{currency_lending: currency_lending}) do
    GenServer.call(currency_lending, :offers_tid)
  end

  @doc false
  def get_account_balance(%{agent: agent, currency: currency}) do
    SecretAgent.account_balance!(to_pid(agent), :lending)[String.to_atom(currency)]
      |> float_to_binary()
  end

  @doc false
  def create_loan_offer(rate, amount, %{agent: agent, currency: currency, duration: duration, auto_renew: auto_renew}) do
    params = [currency: currency, lendingRate: rate, amount: amount, duration: duration, autoRenew: auto_renew]
    {:ok, 200, _} = PrivateAPI.create_loan_offer(to_pid(agent), params)
    # %{message: "Loan order placed.", orderID: 136543484, success: 1}
  end

  defp float_to_binary(nil), do: nil
  defp float_to_binary(float), do: :erlang.float_to_binary(float, [{:decimals, 8}])

  defp to_pid(term) when is_pid(term), do: term
  defp to_pid(term), do: SecretAgent.Supervisor.to_pid_from_identifier(term)
end
