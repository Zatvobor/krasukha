alias Krasukha.{HTTP, Helpers}

defmodule Krasukha.ExchangeRoutines do
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
    spawn(Helpers.Routine, :start_routine, [__MODULE__, strategy, state])
  end

  @doc false
  def default_params() do
    Helpers.Routine.default_params()
      # known options for strategies like `take`
      |> Map.merge(%{fillOrKill: 0, immediateOrCancel: 0, postOnly: 0})
  end

  @doc false
  def init(agent, %{currency_pair: currency_pair, stop_rate: stop_rate, limit_amount: limit_amount} = params) do
    default_params()
      |> Map.merge(params)
      |> Map.merge(%{stop_rate: (stop_rate / 1), limit_amount: (limit_amount / 1)})
      |> Map.merge(%{market: Helpers.Naming.process_name(currency_pair, :market)})
      |> Map.merge(%{agent: agent})
  end

  @doc false
  def buy_lowest(%{agent: agent, currency_pair: currency_pair, market: market} = params) do
    tab = GenServer.call(market, {:book_tid, :asks})
    key = :ets.first(tab)
    possibility = find_possibility_for_order(tab, key, Map.merge(params, %{currency: Helpers.Naming.head_currency_pair(currency_pair)}))
    with {balance, best_amount, rate, stop_rate, order} when (rate < stop_rate and balance > rate * best_amount) <- possibility do
      {:ok, 200, _} = HTTP.PrivateAPI.buy(agent, order)
    end
  end

  @doc false
  def sell_highest(%{agent: agent, currency_pair: currency_pair, market: market} = params) do
    tab = GenServer.call(market, {:book_tid, :bids})
    key = :ets.last(tab)
    possibility = find_possibility_for_order(tab, key, Map.merge(params, %{currency: Helpers.Naming.tail_currency_pair(currency_pair)}))
    with {balance, best_amount, rate, stop_rate, order} when (rate > stop_rate and balance > best_amount) <- possibility do
      {:ok, 200, _} = HTTP.PrivateAPI.sell(agent, order)
    end
  end

  @doc false
  defp find_possibility_for_order(_tab, :"$end_of_table", _params), do: false
  defp find_possibility_for_order(tab, key, %{currency_pair: currency_pair, stop_rate: stop_rate, limit_amount: limit_amount} = params) do
    with balance when is_number(balance) <- Helpers.Routine.get_account_balance(params, :exchange) do
      [{rate, amount}] = :ets.lookup(tab, key)
      best_amount = best_amount(amount, limit_amount)
      order = params
        |> Map.take([:fillOrKill, :immediateOrCancel, :postOnly])
        |> Map.merge(%{currencyPair: currency_pair})
        |> Map.merge(%{rate: Helpers.String.float_to_binary(rate), amount: Helpers.String.float_to_binary(best_amount)})
        |> Map.to_list()
      {balance, best_amount, rate, stop_rate, order}
    end
  end

  defp best_amount(available, provided) when available <= provided, do: available
  defp best_amount(available, provided) when available >= provided, do: provided
end
