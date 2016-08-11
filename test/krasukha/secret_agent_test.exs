defmodule Krasukha.SecretAgentTest do
  use ExUnit.Case, async: true

  import Krasukha.SecretAgent

  setup do
    {:ok, pid} = start_link(%{key: "key", secret: "secret", all: [], active_loans: [], open_loan_offers: []})
    [agent: pid]
  end

  test "key/1", %{agent: pid} do
    assert key(pid) == "key"
  end

  test "secret/1", %{agent: pid} do
    assert secret(pid) == "secret"
  end

  test "key_and_secret/1", %{agent: pid} do
    assert key_and_secret(pid) == {"key", "secret"}
  end

  test "account_balance/1", %{agent: pid} do
    assert account_balance(pid, :all) == []
  end

  test "active_loans/1", %{agent: pid} do
    assert account_balance(pid, :active_loans) == []
  end

  test "open_loan_offers/1", %{agent: pid} do
    assert account_balance(pid, :open_loan_offers) == []
  end

  @tag :skip # @tag [external: true]
  test "fetch_available_account_balance/2"

  @tag :skip # @tag [external: true]
  test "fetch_active_loans/1"
end
