alias Krasukha.{HTTP, Helpers.Naming, Helpers.Routine, Helpers.String}

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
    spawn(Routine, :start_routine, [__MODULE__, strategy, state])
  end

  @doc false
  def default_params() do
    Routine.default_params()
      # known options for strategies like `take`
      |> Map.merge(%{fillOrKill: 0, immediateOrCancel: 0, postOnly: 0})
  end

  @doc false
  def init(agent, %{currency_pair: currency_pair, stop_rate: stop_rate, limit_amount: limit_amount} = params) do
    default_params()
      |> Map.merge(params)
      |> Map.merge(%{stop_rate: (stop_rate / 1), limit_amount: (limit_amount / 1)})
      |> Map.merge(%{market: Naming.process_name(currency_pair, :market)})
      |> Map.merge(%{agent: agent})
  end

  @doc false
  def buy_lowest(%{agent: agent, currency_pair: currency_pair, market: market} = params) do
    tab = GenServer.call(market, {:book_tid, :asks})
    key = :ets.first(tab)
    possibility = find_possibility_for_order(tab, key, Map.merge(params, %{currency: Naming.head_currency_pair(currency_pair)}))
    with {rate, stop_rate, order} when rate < stop_rate <- possibility do
      {:ok, 200, _} = HTTP.PrivateAPI.buy(agent, order)
    end
  end

  @doc false
  def sell_highest(%{agent: agent, currency_pair: currency_pair, market: market} = params) do
    tab = GenServer.call(market, {:book_tid, :bids})
    key = :ets.last(tab)
    possibility = find_possibility_for_order(tab, key, Map.merge(params, %{currency: Naming.tail_currency_pair(currency_pair)}))
    with {rate, stop_rate, order} when rate > stop_rate <- possibility do
      {:ok, 200, _} = HTTP.PrivateAPI.sell(agent, order)
    end
  end

  @doc false
  defp find_possibility_for_order(_tab, :"$end_of_table", _params), do: false
  defp find_possibility_for_order(tab, key, %{currency_pair: currency_pair, stop_rate: stop_rate, limit_amount: limit_amount} = params) do
    balance = Routine.get_account_balance(params, :exchange)
    if is_binary(balance) do
      [{rate, amount}] = :ets.lookup(tab, key)
      order_opts = params
        |> Map.take([:fillOrKill, :immediateOrCancel, :postOnly])
        |> Map.to_list()
        |> Enum.concat([currencyPair: currency_pair, rate: String.float_to_binary(rate), amount: best_amount(amount, limit_amount)])
      {rate, stop_rate, order_opts}
    end
  end

  defp best_amount(available, provided) when available <= provided, do: available
  defp best_amount(available, provided) when available >= provided, do: provided
end
