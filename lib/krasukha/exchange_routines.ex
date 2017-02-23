require Logger
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
    :proc_lib.spawn(Helpers.Routine, :start_routine, [self(), __MODULE__, strategy, state])
  end

  @doc false
  def default_params() do
    Helpers.Routine.default_params()
      # known options for strategies like `buy_lowest/place_highest/sell_highest/place_lowest`
      |> Map.merge(%{stop_rate: :infinity, stop_limit: :infinity, limit_amount: :infinity, stop_limit_acc: 0.0})
      # known options for strategies like `place_highest/place_lowest`
      |> Map.merge(%{spread_rate: Helpers.Routine.satoshi()})
      |> Map.merge(%{fillOrKill: 0, immediateOrCancel: 0, postOnly: 0})
  end

  @doc false
  def init(agent, %{currency_pair: currency_pair} = params) do
    params = Map.merge(default_params(), params)
    params
      |> Map.merge(%{spread_rate: nz(params.spread_rate), stop_rate: nz(params.stop_rate)})
      |> Map.merge(%{limit_amount: nz(params.limit_amount), stop_limit: nz(params.stop_limit)})
      |> Map.merge(%{market: Helpers.Naming.process_name(currency_pair, :market)})
      |> Map.merge(%{agent: agent})
  end

  @doc false
  defdelegate nz(field), to: Helpers.Routine
  @doc false
  defdelegate do_nothing(state), to: Helpers.Routine

  @doc false
  def buy_lowest(params) do
    {_tab, _key, seed} = lookup(:first, :asks, params)
    place_buy_order(seed, params)
  end

  @doc false
  def place_highest(%{limit_amount: limit_amount, spread_rate: spread_rate} = params) when is_float(limit_amount) do
    {_tab, _key, [{rate, _amount}] = _seed} = lookup(:last, :bids, params)
    seed = [{rate + spread_rate, limit_amount}]
    place_buy_order(seed, params)
  end

  @doc false
  def place_buy_order(seed, %{agent: agent, currency_pair: currency_pair} = params) do
    extended_params = Map.merge(params, %{currency: Helpers.Naming.head_currency_pair(currency_pair)})
    with :ok <- check_stop_limit(params),
      possibility = find_possibility_for_order(seed, extended_params),
      {balance, best_amount, rate, stop_rate, order} when (rate < stop_rate) and (balance > (rate * best_amount)) <- possibility,
      {:ok, 200, response} <- HTTP.PrivateAPI.buy(agent, order) do
        response |> inspect |> Logger.info
        accumulate_stop_limit(best_amount, params)
      end
  end

  @doc false
  def sell_highest(params) do
    {_tab, _key, seed} = lookup(:last, :bids, params)
    place_sell_order(seed, params)
  end

  @doc false
  def place_lowest(%{limit_amount: limit_amount, spread_rate: spread_rate}= params) when is_float(limit_amount) do
    {_tab, _key, [{rate, _amount}] = _seed} = lookup(:first, :asks, params)
    seed = [{rate - spread_rate, limit_amount}]
    place_sell_order(seed, params)
  end

  @doc false
  def place_sell_order(seed, %{agent: agent, currency_pair: currency_pair} = params) do
    extended_params = Map.merge(params, %{currency: Helpers.Naming.tail_currency_pair(currency_pair)})
    with :ok <- check_stop_limit(params),
      possibility = find_possibility_for_order(seed, extended_params),
      {balance, best_amount, rate, stop_rate, order} when (rate > stop_rate or stop_rate == :infinity) and (balance > best_amount) <- possibility,
      {:ok, 200, response} <- HTTP.PrivateAPI.sell(agent, order) do
        response |> inspect |> Logger.info
        accumulate_stop_limit(best_amount, params)
      end
  end

  @doc false
  def check_stop_limit(%{stop_limit: :infinity}), do: :ok
  def check_stop_limit(%{stop_limit: stop_limit, stop_limit_acc: stop_limit_acc}) when stop_limit_acc >= stop_limit, do: {:exit, :normal}
  def check_stop_limit(%{stop_limit: stop_limit, stop_limit_acc: stop_limit_acc}) when stop_limit_acc <= stop_limit, do: :ok

  @doc false
  def accumulate_stop_limit(_best_amount, %{stop_limit: :infinity}), do: :ok
  def accumulate_stop_limit(best_amount, %{stop_limit_acc: stop_limit_acc} = params) do
    %{params | stop_limit_acc: (stop_limit_acc + best_amount)}
  end

  @doc false
  defp find_possibility_for_order([], _params), do: false
  defp find_possibility_for_order([{rate, amount}], %{agent: agent, currency: currency, currency_pair: currency_pair, stop_rate: stop_rate, limit_amount: limit_amount} = params) do
    with balance when is_number(balance) <- Krasukha.SecretAgent.account_balance!(agent, :exchange, currency) do
      best_amount = best_amount(amount, limit_amount)
      order = params
        |> Map.take([:fillOrKill, :immediateOrCancel, :postOnly])
        |> Map.merge(%{currencyPair: currency_pair})
        |> Map.merge(%{rate: Helpers.String.float_to_binary(rate), amount: Helpers.String.float_to_binary(best_amount)})
        |> Map.to_list()
      {balance, best_amount, rate, stop_rate, order}
    end
  end

  @doc false
  defp best_amount(available, limit_amount) when available <= limit_amount, do: available
  defp best_amount(available, limit_amount) when available >= limit_amount, do: limit_amount

  @doc false
  defp lookup(what, type, %{market: market}), do: lookup(what, type, market)
  defp lookup(what, type, market) do
    tab = GenServer.call(market, {:book_tid, type})
    key = apply(:ets, what, [tab])
    seed = :ets.lookup(tab, key)
    {tab, key, seed}
  end
end
