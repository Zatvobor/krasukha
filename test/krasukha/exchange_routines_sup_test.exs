alias Krasukha.{Supervisor}
import Krasukha.ExchangeRoutines.Supervisor

defmodule Krasukha.ExchangeRoutines.SupervisorTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = Krasukha.start_secret_agent("key", "secret")
    Supervisor.restart_child(Krasukha.ExchangeRoutines.Supervisor)
    on_exit fn -> Supervisor.terminate_child(Krasukha.ExchangeRoutines.Supervisor) end
    [agent: pid]
  end

  describe "child context" do
    setup %{agent: agent} do
      for currency <- ["X", "Y"] do
        {:ok, _} = Krasukha.start_exchange_routine(agent, :do_nothing, %{currency_pair: currency})
      end
    end

    test "terminate_children/0" do
      actual = terminate_children()
      assert actual == [:ok, :ok]
    end

    test "restart_children/0" do
      terminate_children()
      actual = restart_children()
      assert [{:ok, _}, {:ok, _}] = actual
    end

    test "delete_children/0" do
      terminate_children()
      actual = delete_children()
      assert actual == [:ok, :ok]
    end

    test "get_childrenspec/0" do
      actual = get_childrenspec()
      assert [{:ok, _}, {:ok, _}] = actual
    end
  end
end
