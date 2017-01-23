defmodule Krasukha do
  @moduledoc false

  use Application

  import Supervisor.Spec, warn: false, only: [supervisor: 3, worker: 3]

  alias Krasukha.{Helpers.Naming, SecretAgent, MarketsGen, MarketGen, LendingGen, WAMP}


  @doc false
  def start(:normal, _args \\ nil) do
    Krasukha.Supervisor.start_link()
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
    id = Naming.process_name(currency_pair, :market)
    spec = worker(MarketGen, [currency_pair], [id: id, restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def start_market!(currency_pair, initial_requests \\ [{:fetch_order_book, [depth: 10]}, :subscribe]) do
    {:ok, pid} = start_market(currency_pair)
    init(pid, initial_requests)
  end

  @doc false
  def start_lending(currency) do
    id = Naming.process_name(currency, :lending)
    spec = worker(LendingGen, [currency], [id: id, restart: :transient])
    Supervisor.start_child(Krasukha.Supervisor, spec)
  end

  @doc false
  def start_lending!(currency, update_loan_orders_every_sec \\ 60) do
    {:ok, pid} = start_lending(currency)
    initial_requests = [{:update_loan_orders, [every: update_loan_orders_every_sec]}]
    init(pid, initial_requests)
  end

  @doc false
  def start_lending_routine(agent, strategy, params) do
    start_routine(Krasukha.LendingRoutines, agent, strategy, params)
  end

  @doc false
  def start_exchange_routine(agent, strategy, params) do
    start_routine(Krasukha.ExchangeRoutines, agent, strategy, params)
  end

  @doc false
  def start_routine(mod, agent, strategy, params) do
    id = make_id()
    identifier = SecretAgent.identifier(agent)
    spec = worker(mod, [identifier, strategy, params], [id: id, restart: :transient])
    state = Supervisor.start_child(Module.concat(mod, Supervisor), spec)
    with {:ok, _pid} <- state, do: SecretAgent.put_routine(agent, id)
    state
  end

  @doc false
  def start_secret_agent(key, secret) do
    id = make_id()
    spec = worker(SecretAgent, [key, secret, id], [id: id, restart: :permanent])
    Supervisor.start_child(Krasukha.SecretAgent.Supervisor, spec)
  end


  defp init(pid, initial_requests) do
    responses = Enum.map(initial_requests, fn(request) -> GenServer.call(pid, request) end)
    {:ok, pid, responses}
  end

  defp make_id(), do: :erlang.unique_integer([:monotonic])
end
