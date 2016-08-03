defmodule KrasukhaTest do
  use ExUnit.Case

  doctest Krasukha
  import Krasukha

  setup_all do
    :ok = Application.ensure_started(:krasukha)
  end


  test "start_markets/0" do
    assert {:ok, _pid} = start_markets()
  end

  test "start_market/1" do
    assert {:ok, _pid} = start_market("untitled")
  end

  test "start_secret_agent/2" do
    assert {:ok, _pid} = start_secret_agent("key", "secret")
  end
end
