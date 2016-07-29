defmodule Krasukha do
  @moduledoc false

  use Application

  import Supervisor.Spec, warn: false, only: [worker: 3]

  @doc false
  def start(:normal, _args \\ nil) do
    opts = [strategy: :one_for_one, name: Krasukha.Supervisor]
    Supervisor.start_link([], opts)
  end

  @doc false
  def start_wamp_connection, do: Krasukha.WAMP.connect!

  @doc false
  def start_markets do
    spec = worker(Krasukha.MarketsGen, [], [restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def start_market(currency_pair) do
    import Krasukha.MarketGen, only: [to_name: 2]
    spec = worker(Krasukha.MarketGen, [currency_pair], [id: to_name(currency_pair, :market), restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def stop(_state) do
    Krasukha.WAMP.disconnect!()
  end
end
