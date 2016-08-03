defmodule Krasukha.SecretAgentTest do
  use ExUnit.Case, async: true

  import Krasukha.SecretAgent

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
end
