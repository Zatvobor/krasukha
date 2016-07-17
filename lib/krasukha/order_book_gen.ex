require Logger

defmodule Krasukha.OrderBookGen do
  @moduledoc false

  use GenServer

  @doc false
  def start_link(currency_pair) do
    options = [name: currency_pair]
    GenServer.start_link(__MODULE__, [currency_pair], options)
  end

  @doc false
  def init([currency_pair]) do
    {:ok, subscriber} = Spell.connect("wss://api.poloniex.com", realm: "realm1")
    {:ok, subscription} = Spell.call_subscribe(subscriber, to_string(currency_pair))

    case Spell.receive_event(subscriber, subscription) do
      {:ok, event}     -> Logger.info(inspect(event))
      {:error, reason} -> {:error, reason}
    end

    {:ok, [subscriber, subscription]}
  end

  @doc false
  def terminate(reason, [subscriber, subscription]) do
    Spell.call_unsubscribe(subscriber, subscription)
    Spell.close(subscriber)

    :ok
  end
end
