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
    spawn(Helpers.Routine, :start_routine, [__MODULE__, strategy, state])
  end

  @doc false
  def default_params() do
    Helpers.Routine.default_params()
      # known options for strategies like `buy_lowest/sell_highest`
      |> Map.merge(%{stop_rate: :infinity, stop_limit: :infinity, stop_limit_acc: 0.0})
      |> Map.merge(%{fillOrKill: 0, immediateOrCancel: 0, postOnly: 0})
  end

  @doc false
  def init(agent, %{currency_pair: currency_pair, limit_amount: limit_amount} = params) do
    default_params()
      |> Map.merge(params)
      |> Map.merge(%{stop_rate: nz(params.stop_rate), stop_limit: nz(params.stop_limit)})
      |> Map.merge(%{limit_amount: nz(limit_amount)})
      |> Map.merge(%{market: Helpers.Naming.process_name(currency_pair, :market)})
      |> Map.merge(%{agent: agent})
  end

  defp nz(field) when field in [:inifinity], do: field
  defp nz(field) when is_integer(field), do: (field / 1)
  defp nz(field) when is_float(field), do: field

  @doc false
  defmacro is_buy_lowest_possibility(rate, stop_rate, balance, best_amount) do
    quote do
      (unquote(rate) < unquote(stop_rate)) and (unquote(balance) > unquote(rate) * unquote(best_amount))
    end
  end

  @doc false
  def buy_lowest(%{agent: agent, currency_pair: currency_pair, market: market} = params) do
    tab = GenServer.call(market, {:book_tid, :asks})
    key = :ets.first(tab)
    extended_params = Map.merge(params, %{currency: Helpers.Naming.head_currency_pair(currency_pair)})
    with :ok <- check_stop_limit(params),
      possibility = find_possibility_for_order(tab, key, extended_params),
      {balance, best_amount, rate, stop_rate, order} when is_buy_lowest_possibility(rate, stop_rate, balance, best_amount) <- possibility,
      {:ok, 200, response} <- HTTP.PrivateAPI.buy(agent, order) do
        # %{orderNumber: "24213262617", resultingTrades: [%{amount: "15.00000000", date: "2017-01-30 17:52:44", rate: "0.00000696", total: "0.00010440", tradeID: "1600555", type: "buy"}]}
        # %{orderNumber: "24212832048", resultingTrades: []}
        response |> inspect |> Logger.info
        accumulate_stop_limit(best_amount, params)
      end
  end

  @doc false
  defmacro is_sell_highest_possibility(rate, stop_rate, balance, best_amount) do
    quote do
      (unquote(rate) > unquote(stop_rate) or unquote(stop_rate) == :infinity) and (unquote(balance) > unquote(best_amount))
    end
  end

  @doc false
  def sell_highest(%{agent: agent, currency_pair: currency_pair, market: market} = params) do
    tab = GenServer.call(market, {:book_tid, :bids})
    key = :ets.last(tab)
    extended_params = Map.merge(params, %{currency: Helpers.Naming.tail_currency_pair(currency_pair)})
    with :ok <- check_stop_limit(params),
      possibility = find_possibility_for_order(tab, key, extended_params),
      {balance, best_amount, rate, stop_rate, order} when is_sell_highest_possibility(rate, stop_rate, balance, best_amount) <- possibility,
      {:ok, 200, response} <- HTTP.PrivateAPI.sell(agent, order) do
        # %{}
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
    %{params | stop_limit_acc: stop_limit_acc + best_amount}
  end

  @doc false
  defp find_possibility_for_order(_tab, :"$end_of_table", _params), do: false
  defp find_possibility_for_order(tab, key, %{agent: agent, currency: currency, currency_pair: currency_pair, stop_rate: stop_rate, limit_amount: limit_amount} = params) do
    with balance when is_number(balance) <- Krasukha.SecretAgent.account_balance!(agent, :exchange, currency) do
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
