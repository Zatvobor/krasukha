alias Krasukha.{SecretAgent, SecretAgent.Supervisor}

defmodule Krasukha.SecretAgent.SupervisorTest do
  use ExUnit.Case, async: true

  setup_all do
    :ok = Application.ensure_started(:krasukha)
  end

  setup do
    {:ok, pid} = Krasukha.start_secret_agent("key", "secret")
    [agent: pid]
  end

  test "to_pid_from_identifier/1", %{agent: pid} do
    actual = Supervisor.to_pid_from_identifier(:unknown)
    assert actual == nil

    actual = (SecretAgent.identifier(pid) |> Supervisor.to_pid_from_identifier())
    assert actual == pid
  end

  test "shutdown_routines/2", %{agent: pid} do
    routine = spawn(fn -> :ok end)
    assert :ok = SecretAgent.update_routines(pid, [routine])
    assert Supervisor.shutdown_routines(pid) == [true]
  end
end
