defmodule Krasukha do
  @moduledoc false

  use Application

  import Supervisor.Spec, warn: false, only: [supervisor: 3, worker: 3]

  alias Krasukha.{Helpers.Naming, SecretAgent, MarketsGen, MarketGen, LendingGen, LendingRoutines, WAMP}


  @doc false
  def start(:normal, _args \\ nil) do
    children = [
      supervisor(
        Supervisor,
        [[], [strategy: :one_for_one, name: Krasukha.SecretAgent.Supervisor]],
        [id: Krasukha.SecretAgent.Supervisor, restart: :permanent]
      ),
      supervisor(
        Supervisor,
        [[], [strategy: :one_for_one, name: Krasukha.Lending.Supervisor]],
        [id: Krasukha.Lending.Supervisor, restart: :permanent]
      )
    ]
    opts = [strategy: :one_for_one, name: Krasukha.Supervisor]
    Supervisor.start_link(children, opts)
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
    id = make_id()
    spec = worker(LendingRoutines, [agent, strategy, params], [id: id, restart: :transient])
    Supervisor.start_child(Krasukha.Lending.Supervisor, spec)
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
