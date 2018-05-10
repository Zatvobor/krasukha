defmodule Krasukha do
  use Application

  @moduledoc false

  @doc false
  def start(:normal, _args \\ nil), do: Krasukha.Supervisor.start_link()
  @doc false
  def stop(_state), do: stop_wamp_connection()

  @doc false
  def start_wamp_connection, do: GenServer.call(:wamp_gen, :connect)
  @doc false
  def stop_wamp_connection, do: GenServer.call(:wamp_gen, :disconnect)

  @doc false
  def start_markets(preflight_opts \\ []) do
    spec = Supervisor.Spec.worker(Krasukha.MarketsGen, [preflight_opts], [restart: :transient])
    Supervisor.start_child(Krasukha.WAMP.Subscribed.Supervisor, spec)
  end

  @doc false
  def start_markets!(update_ticker_every_sec \\ 60) do
    start_markets([:fetch_ticker, {:update_ticker, [every: update_ticker_every_sec]}])
  end

  alias Krasukha.{Helpers.Naming}

  @doc false
  def start_market(params, preflight_opts \\ [])
  def start_market(currency_pair, preflight_opts) when is_binary(currency_pair) do
    start_market(%{currency_pair: currency_pair}, preflight_opts)
  end
  def start_market(%{currency_pair: currency_pair} = params, preflight_opts) when is_binary(currency_pair) do
    id = Naming.monotonic_id()
    spec = Supervisor.Spec.worker(Krasukha.MarketGen, [params, preflight_opts], [id: id, restart: :transient])
    Supervisor.start_child(Krasukha.WAMP.Subscribed.Supervisor, spec)
  end

  @doc false
  def start_market!(currency_pair, order_book_depth \\ 55, update_order_books_every_sec \\ 60)
  def start_market!(currency_pair, order_book_depth, update_order_books_every_sec) when is_binary(currency_pair) do
    preflight_opts = [{:fetch_order_books, [currencyPair: currency_pair, depth: order_book_depth]}, {:update_order_books, [every: update_order_books_every_sec]}]
    start_market(%{currency_pair: currency_pair, order_book_depth: order_book_depth}, preflight_opts)
  end

  @doc false
  def start_market!(currency_pair, order_book_depth, preflight_opts) when is_binary(currency_pair) do
    start_market(%{currency_pair: currency_pair, order_book_depth: order_book_depth}, preflight_opts)
  end

  @doc false
  def start_lending(currency, preflight_opts \\ []) when is_binary(currency) do
    id = Naming.monotonic_id()
    spec = Supervisor.Spec.worker(Krasukha.LendingGen, [currency, preflight_opts], [id: id, restart: :transient])
    Supervisor.start_child(Krasukha.LendingRoutines.Supervisor, spec)
  end
  @doc false
  def start_lending!(currency, update_loan_orders_every_sec \\ 60) when is_binary(currency) do
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
