defmodule Krasukha.SecretAgent do
  @moduledoc false

  import Krasukha.Helpers.String
  alias Krasukha.{HTTP.PrivateAPI}


  @doc false
  def start_link(key, secret), do: start_link(%{key: key, secret: secret})

  @doc false
  def start_link(%{} = state) do
    Agent.start_link(fn -> state end)
  end

  @doc false
  def key(agent), do: Agent.get(agent, fn(%{key: k}) -> k end)

  @doc false
  def secret(agent), do: Agent.get(agent, fn(%{secret: s}) -> s end)

  @doc false
  def key_and_secret(agent), do: Agent.get(agent, fn(%{key: k, secret: s}) -> {k,s} end)

  @doc false
  def account_balance(agent, account \\ :all), do: Agent.get(agent, fn(%{^account => a}) -> a end)

  @doc false
  def account_balance!(agent, account \\ :all) do
    :ok = fetch_available_account_balance(agent, account)
    account_balance(agent, account)
  end

  @doc false
  def fetch_available_account_balance(agent, account \\ :all) do
    {:ok, 200, payload} = PrivateAPI.return_available_account_balances(agent, [account: account])
    payload = Enum.map(payload[account], fn({k,v}) -> {k, to_float(v)} end)
    :ok = Agent.update(agent, fn(state) -> Map.put(state, account, payload) end)
  end

  @doc false
  def active_loans(agent), do: Agent.get(agent, fn(%{active_loans: l}) -> l end)

  @doc false
  def active_loans!(agent) do
    :ok = fetch_active_loans(agent)
    active_loans(agent)
  end

  @doc false
  def fetch_active_loans(agent) do
    {:ok, 200, payload} = PrivateAPI.return_active_loans(agent)
    payload = map_nested_values(payload, fn(record) ->
      {rate, amount, fees} = to_tuple_with_floats(record)
      %{record| rate: rate, amount: amount, fees: fees}
    end)
    :ok = Agent.update(agent, fn(state) -> Map.put(state, :active_loans, payload) end)
  end

  @doc false
  def open_loan_offers(agent), do: Agent.get(agent, fn(%{open_loan_offers: l}) -> l end)

  @doc false
  def open_loan_offers!(agent) do
    :ok = fetch_open_loan_offers(agent)
    open_loan_offers(agent)
  end

  @doc false
  def fetch_open_loan_offers(agent) do
    {:ok, 200, payload} = PrivateAPI.return_open_loan_offers(agent)
    payload = map_nested_values(payload, fn(record) ->
      {rate, amount} = to_tuple_with_floats(record)
      %{record | rate: rate, amount: amount}
    end)
    :ok = Agent.update(agent, fn(state) -> Map.put(state, :open_loan_offers, payload) end)
  end


  defp map_nested_values(payload, fun) do
    Enum.map(payload, fn({k,v}) -> {k, Enum.map(v, fun)} end)
      |> Map.new
  end
end
