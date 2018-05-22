alias Krasukha.HTTP

defmodule Krasukha.HTTP.PublicAPI do
  @moduledoc false

  @doc false
  def uri, do: %URI{ HTTP.uri | path: "/public" }

  @doc false
  def return_order_book(params \\ [currencyPair: "BTC_NXT", depth: 1]) do
    HTTP.url("returnOrderBook", params, uri)
      |> HTTP.get
  end

  @doc false
  def return_trade_history(params \\ [currencyPair: "BTC_NXT"]) do
    HTTP.url("returnTradeHistory", params, uri)
      |> HTTP.get
  end

  @doc false
  def return_ticker() do
    HTTP.url("returnTicker", [], uri)
      |> HTTP.get
  end

  @doc false
  def return_loan_orders(currency) do
    HTTP.url("returnLoanOrders", [currency: currency], uri)
      |> HTTP.get
  end
end
