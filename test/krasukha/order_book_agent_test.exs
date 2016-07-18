alias Krasukha.OrderBookAgent

defmodule Krasukha.OrderBookAgentTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = OrderBookAgent.start_link()
    [agent: pid]
  end

  test "asks_book_tid/1", %{agent: pid} do
    assert OrderBookAgent.asks_book_tid(pid)
  end

  test "bids_book_tid/1", %{agent: pid} do
    assert OrderBookAgent.bids_book_tid(pid)
  end

  test "stop/1", %{agent: pid} do
    assert(OrderBookAgent.stop(pid) == :ok)
  end
end
