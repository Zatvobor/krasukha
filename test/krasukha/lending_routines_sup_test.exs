defmodule Krasukha.LendingRoutines.SupervisorTest do
  use ExUnit.Case, async: true

  import Krasukha.LendingRoutines.Supervisor
  alias Krasukha.{Supervisor}

  setup do
    {:ok, pid} = Krasukha.start_secret_agent("key", "secret")
    Supervisor.restart_child(Krasukha.LendingRoutines.Supervisor)
    on_exit fn -> Supervisor.terminate_child(Krasukha.LendingRoutines.Supervisor) end
    [agent: pid]
  end


  describe "child context" do
    setup %{agent: agent} do
      for currency <- ["X", "Y"] do
        {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: currency})
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
