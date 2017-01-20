defmodule Krasukha.LendingRoutines.SupervisorTest do
  use ExUnit.Case, async: true

  import Krasukha.LendingRoutines.Supervisor
  alias Krasukha.{SecretAgent}

  setup do
    {:ok, pid} = Krasukha.start_secret_agent("key", "secret")
    Supervisor.restart_child(Krasukha.Supervisor, Krasukha.LendingRoutines.Supervisor)
    on_exit fn -> Supervisor.terminate_child(Krasukha.Supervisor, Krasukha.LendingRoutines.Supervisor) end
    [agent: pid]
  end


  test "to_pid_from_identifier(:unknown)" do
    actual = to_pid_from_identifier(:unknown)
    assert actual == nil
  end

  test "to_pid_from_identifier/1", %{agent: agent} do
    {:ok, pid} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "X"})
    actual = (SecretAgent.routines(agent) |> List.first |> to_pid_from_identifier())
    assert actual == pid
  end

  test "terminate_children/0", %{agent: agent} do
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "X"})
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "Y"})
    actual = terminate_children()
    assert actual == [:ok, :ok]
  end

  test "restart_children/0", %{agent: agent} do
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "X"})
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "Y"})
    terminate_children()
    actual = restart_children()
    assert [{:ok, _}, {:ok, _}] = actual
  end

  test "delete_children/0", %{agent: agent} do
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "X"})
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "Y"})
    terminate_children()
    actual = delete_children()
    assert actual == [:ok, :ok]
  end

  test "get_childrenspec/0", %{agent: agent} do
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "X"})
    {:ok, _} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "Y"})
    actual = get_childrenspec()
    assert [{:ok, _}, {:ok, _}] = actual
  end
end
