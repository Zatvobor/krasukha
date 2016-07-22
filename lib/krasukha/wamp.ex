defmodule Krasukha.WAMP do
  @moduledoc false

  @uri URI.parse("wss://api.poloniex.com")
  @doc false
  def uri, do: @uri

  @doc false
  def url, do: uri |> to_string
end
