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
  def start_markets!(initial_requests \\ [:fetch_ticker, :subscribe_ticker]) do
    {:ok, pid} = start_markets()
    init(pid, initial_requests)
  end

  @doc false
  def start_market(currency_pair) do
    import Krasukha.MarketGen, only: [to_name: 2]
    spec = worker(Krasukha.MarketGen, [currency_pair], [id: to_name(currency_pair, :market), restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def start_market!(currency_pair, initial_requests \\ [{:fetch_order_book, [depth: 10]}, :subscribe]) do
    {:ok, pid} = start_market(currency_pair)
    init(pid, initial_requests)
  end

  @doc false
  def stop(_state) do
    Krasukha.WAMP.disconnect!()
  end


  defp init(pid, initial_requests) do
    responses = Enum.map(initial_requests, fn(request) -> GenServer.call(pid, request) end)
    {:ok, pid, responses}
  end
end
