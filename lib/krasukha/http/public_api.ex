defmodule Krasukha.HTTP.PublicAPI do
  @moduledoc false

  alias Krasukha.HTTP

  @doc false
  def uri, do: %URI{ HTTP.uri | path: "/public" }

  @doc false
  def return_order_book(params \\ [currencyPair: "BTC_NXT", depth: 1]) do
    url = HTTP.url("returnOrderBook", params, uri)
    HTTP.get(url)
  end

  @doc false
  def return_ticker() do
    url = HTTP.url("returnTicker", [], uri)
    HTTP.get(url)
  end

  @doc false
  def to_tuple_with_floats([rate, amount]), do: {to_float(rate), to_float(amount)}
  def to_tuple_with_floats(%{"rate" => rate, "amount" => amount}), do: {to_float(rate), to_float(amount)}

  @doc false
  def to_float(value) when is_binary(value) do
    String.to_float(value)
  rescue
    ArgumentError -> String.to_integer(value)
  end
  def to_float(value), do: value
end
