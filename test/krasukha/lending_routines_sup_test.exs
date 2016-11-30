defmodule Krasukha.LendingRoutines.SupervisorTest do
  use ExUnit.Case, async: true

  alias Krasukha.{SecretAgent, LendingRoutines.Supervisor}

  setup_all do
    :ok = Application.ensure_started(:krasukha)
  end


  test "to_pid_from_identifier/1" do
    actual = Supervisor.to_pid_from_identifier(:unknown)
    assert actual == nil

    assert {:ok, agent} = Krasukha.start_secret_agent("key", "secret")
    assert {:ok, pid} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "X"})
    actual = (SecretAgent.routines(agent) |> List.first |> Supervisor.to_pid_from_identifier())
    assert actual == pid
  end
end
