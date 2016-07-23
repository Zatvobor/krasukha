defmodule Krasukha.HTTP.PublicAPI do
  @moduledoc false

  alias Krasukha.HTTP

  @doc false
  def uri, do: %URI{ HTTP.uri | path: "/public" }

  @doc false
  def return_order_book(params \\ [currencyPair: "BTC_NXT", depth: 1]) do
    url = HTTP.url("returnOrderBook", params, uri)
    response = HTTP.get(url)
    normalize_return_order_book(response)
  end

  @doc false
  def normalize_return_order_book({:ok, 200, body}), do: {:ok, 200, normalize_return_order_book(body)}
  def normalize_return_order_book(%{asks: asks, bids: bids} = body), do: Map.merge(body, %{asks: normalize_return_order_book(asks), bids: normalize_return_order_book(bids)})
  def normalize_return_order_book([price, amount]) when is_binary(price), do: [String.to_float(price), amount]
  def normalize_return_order_book(slot) when is_list(slot), do: Enum.map(slot, &(normalize_return_order_book(&1)))
  def normalize_return_order_book(:error), do: :error
end
