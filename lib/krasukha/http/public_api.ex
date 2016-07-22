defmodule Krasukha.HTTP.PublicAPI do
  @moduledoc false

  alias Krasukha.HTTP

  @doc false
  def uri, do: %URI{ HTTP.uri | path: "/public" }

  @doc false
  def returnOrderBook(params \\ [currencyPair: "BTC_NXT", depth: 1]) do
    url = HTTP.url("returnOrderBook", params, uri)
    response = HTTP.get(url)
    normalizeReturnOrderBook(response)
  end

  @doc false
  def normalizeReturnOrderBook({:ok, 200, body}), do: {:ok, 200, normalizeReturnOrderBook(body)}
  def normalizeReturnOrderBook(%{asks: asks, bids: bids} = body), do: Map.merge(body, %{asks: normalizeReturnOrderBook(asks), bids: normalizeReturnOrderBook(bids)})
  def normalizeReturnOrderBook([price, amount]) when is_binary(price), do: [String.to_float(price), amount]
  def normalizeReturnOrderBook(slot) when is_list(slot), do: Enum.map(slot, &(normalizeReturnOrderBook(&1)))
  def normalizeReturnOrderBook(:error), do: :error
end
