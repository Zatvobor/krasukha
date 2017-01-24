import Krasukha.SecretAgent

defmodule Krasukha.SecretAgentTest do
  use ExUnit.Case, async: true

  describe "agent w/ identifier" do
    test "start_link/3" do
      {:ok, pid} = start_link("key", "secret", "identifier")
      assert key(pid) == "key"
      assert secret(pid) == "secret"
      assert identifier(pid) == "identifier"
    end
  end

  setup do
    {:ok, pid} = start_link("key", "secret")
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

  test "routines/1", %{agent: pid} do
    assert routines(pid) == []
  end

  test "put_routine/2", %{agent: pid} do
    assert :ok = put_routine(pid, 123)
    assert routines(pid) == [123]
  end

  test "update_routines/2", %{agent: pid} do
    assert :ok = update_routines(pid, [1,2])
    assert routines(pid) == [1,2]
  end

  @tag :skip # @tag [external: true]
  test "fetch_available_account_balance/2"

  @tag :skip # @tag [external: true]
  test "fetch_active_loans/1"
end
