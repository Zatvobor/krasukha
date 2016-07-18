require Logger

defmodule Krasukha.OrderBookGen do
  @moduledoc false

  use GenServer
  alias Krasukha.OrderBookAgent

  @doc false
  def start_link(currency_pair) do
    options = [name: currency_pair]
    GenServer.start_link(__MODULE__, [currency_pair], options)
  end

  @doc false
  def init([currency_pair]) do
    {:ok, order_book} = OrderBookAgent.start_link()

    {:ok, subscriber} = Spell.connect("wss://api.poloniex.com", realm: "realm1")
    {:ok, subscription} = Spell.call_subscribe(subscriber, to_string(currency_pair))

    case Spell.receive_event(subscriber, subscription) do
      {:ok, event}     -> Logger.info(inspect(event))
      {:error, reason} -> {:error, reason}
    end

    {:ok, [subscriber, subscription, order_book]}
  end

  @doc false
  def terminate(_reason, [subscriber, subscription, order_book]) do
    :ok = Spell.call_unsubscribe(subscriber, subscription)
    :ok = Spell.close(subscriber)
    :ok = OrderBookAgent.stop(order_book)

    :ok
  end
end
