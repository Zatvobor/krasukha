import Krasukha

defmodule KrasukhaTest do
  use ExUnit.Case

  doctest Krasukha

  setup_all do
    :ok = Application.ensure_started(:krasukha)
  end

  @tag :external
  test "starts and stops WAMP connection" do
    assert {:ok, pid} = start_wamp_connection
    assert Process.alive?(pid)
    assert :ok = stop_wamp_connection
    refute Process.alive?(pid)
  end

  test "start_markets/0" do
    assert {:ok, pid} = start_markets()
    assert Process.alive?(pid)
  end

  @tag :external
  test "start_market!/1" do
    {:ok, _pid} = start_wamp_connection
    assert {:ok, pid} = start_market!("BTC_SC")
    assert Process.alive?(pid)
    :ok = stop_wamp_connection
  end

  test "start_market/1" do
    assert {:ok, pid} = start_market("BTC_SC")
    assert Process.alive?(pid)
    assert {:ok, pid} = start_market(%{currency_pair: "BTC_DASH"})
    assert Process.alive?(pid)
  end

  test "start_secret_agent/2" do
    assert {:ok, pid} = start_secret_agent("key", "secret")
    assert Process.alive?(pid)
  end
end
