defmodule Krasukha do
  use Application

  @moduledoc false

  @doc false
  def start(:normal, _args \\ nil), do: Krasukha.Supervisor.start_link()
  @doc false
  def stop(_state), do: stop_wamp_connection()

  @doc false
  def start_wamp_connection, do: GenServer.call(Krasukha.WAMPGen, :connect)
  @doc false
  def stop_wamp_connection, do: Krasukha.WAMP.disconnect!()

  @doc false
  def start_markets(preflight_opts \\ []) do
    spec = Supervisor.Spec.worker(Krasukha.MarketsGen, [preflight_opts], [restart: :transient])
    Supervisor.start_child(Krasukha.WAMP.Subscribed.Supervisor, spec)
  end

  @doc false
  def start_markets!() do
    start_markets([:fetch_ticker, :subscribe_ticker])
  end

  alias Krasukha.{Helpers.Naming}

  @doc false
  def start_market(currency_pair, preflight_opts \\ []) do
    id = Naming.process_name(currency_pair, :market)
    spec = Supervisor.Spec.worker(Krasukha.MarketGen, [currency_pair, preflight_opts], [id: id, restart: :transient])
    Supervisor.start_child(Krasukha.WAMP.Subscribed.Supervisor, spec)
  end

  @doc false
  def start_market!(currency_pair) do
    preflight_opts = [{:fetch_order_book, [currencyPair: currency_pair, depth: 10]}, :subscribe]
    start_market(currency_pair, preflight_opts)
  end

  @doc false
  def start_lending(currency, preflight_opts \\ []) do
    id = Naming.process_name(currency, :lending)
    spec = Supervisor.Spec.worker(Krasukha.LendingGen, [currency, preflight_opts], [id: id, restart: :transient])
    Supervisor.start_child(Krasukha.LendingRoutines.Supervisor, spec)
  end
  @doc false
  def start_lending!(currency, update_loan_orders_every_sec \\ 60) do
    preflight_opts = [{:update_loan_orders, [every: update_loan_orders_every_sec]}]
    start_lending(currency, preflight_opts)
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
    id = Naming.monotonic_id()
    identifier = Krasukha.SecretAgent.identifier(agent)
    spec = Supervisor.Spec.worker(mod, [identifier, strategy, params], [id: id, restart: :transient])
    state = Supervisor.start_child(Module.concat(mod, Supervisor), spec)
    with {:ok, _pid} <- state, do: Krasukha.SecretAgent.put_routine(agent, id)
    state
  end

  @doc false
  def start_secret_agent(key, secret) do
    id = Naming.monotonic_id()
    spec = Supervisor.Spec.worker(Krasukha.SecretAgent, [key, secret, id], [id: id, restart: :permanent])
    Supervisor.start_child(Krasukha.SecretAgent.Supervisor, spec)
  end
end
