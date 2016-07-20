defmodule Krasukha.HTTP.PublicAPI do
  @moduledoc false

  alias Krasukha.HTTP

  @doc false
  def uri, do: %URI{ HTTP.uri | path: "/public" }

  @doc false
  def returnOrderBook(params \\ [currencyPair: "BTC_NXT", depth: 1]) do
    url = HTTP.url("returnOrderBook", params, uri)
    HTTP.get(url)
  end
end
