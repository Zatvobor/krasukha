alias Krasukha.OrderBookAgent

defmodule Krasukha.OrderBookAgentTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = OrderBookAgent.start_link()
    [agent: pid]
  end

  test "book_tids/1", %{agent: pid} do
    assert [_,_] = OrderBookAgent.book_tids(pid)
  end

  test "asks_book_tid/1", %{agent: pid} do
    tid = OrderBookAgent.asks_book_tid(pid)
    assert :ordered_set = :ets.info(tid, :type)
  end

  test "bids_book_tid/1", %{agent: pid} do
    tid = OrderBookAgent.bids_book_tid(pid)
    assert :ordered_set = :ets.info(tid, :type)
  end

  test "stop/1", %{agent: pid} do
    book_tids = OrderBookAgent.book_tids(pid)
    assert :ok = OrderBookAgent.stop(pid)
    Enum.map(book_tids, fn (tid) ->
      assert :undefined = :ets.info(tid, :type)
    end)
  end
end
