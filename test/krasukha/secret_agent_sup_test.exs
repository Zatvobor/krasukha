defmodule Krasukha.SecretAgent.SupervisorTest do
  use ExUnit.Case, async: true

  alias Krasukha.{SecretAgent, SecretAgent.Supervisor}

  setup_all do
    :ok = Application.ensure_started(:krasukha)
  end


  test "to_pid_from_identifier/1" do
    actual = Supervisor.to_pid_from_identifier(:unknown)
    assert actual == nil

    assert {:ok, pid} = Krasukha.start_secret_agent("key", "secret")
    actual = (SecretAgent.identifier(pid) |> Supervisor.to_pid_from_identifier())
    assert actual == pid
  end
end
