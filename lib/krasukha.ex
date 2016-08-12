defmodule Krasukha do
  @moduledoc false

  use Application

  import Supervisor.Spec, warn: false, only: [worker: 3]

  alias Krasukha.{Helpers.Naming, SecretAgent, MarketsGen, MarketGen, LendingGen, WAMP}


  @doc false
  def start(:normal, _args \\ nil) do
    opts = [strategy: :one_for_one, name: Krasukha.Supervisor]
    Supervisor.start_link([], opts)
  end

  @doc false
  def stop(_state), do: WAMP.disconnect!()


  @doc false
  def start_wamp_connection, do: WAMP.connect!

  @doc false
  def start_markets do
    spec = worker(MarketsGen, [], [restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def start_markets!(initial_requests \\ [:fetch_ticker, :subscribe_ticker]) do
    {:ok, pid} = start_markets()
    init(pid, initial_requests)
  end

  @doc false
  def start_market(currency_pair) do
    spec = worker(MarketGen, [currency_pair], [id: Naming.process_name(currency_pair, :market), restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def start_market!(currency_pair, initial_requests \\ [{:fetch_order_book, [depth: 10]}, :subscribe]) do
    {:ok, pid} = start_market(currency_pair)
    init(pid, initial_requests)
  end

  @doc false
  def start_lending(currency) do
    spec = worker(LendingGen, [currency], [id: Naming.process_name(currency, :lending), restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def start_lending!(currency, update_loan_orders_every_sec \\ 60) do
    {:ok, pid} = start_lending(currency)
    initial_requests = [{:update_loan_orders, [every: update_loan_orders_every_sec]}]
    init(pid, initial_requests)
  end

  @doc false
  def start_secret_agent(key, secret) do
    spec = worker(SecretAgent, [key, secret], [restart: :permanent])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end


  defp init(pid, initial_requests) do
    responses = Enum.map(initial_requests, fn(request) -> GenServer.call(pid, request) end)
    {:ok, pid, responses}
  end
end
