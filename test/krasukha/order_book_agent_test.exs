defmodule Krasukha.OrderBookAgentTest do
  use ExUnit.Case, async: true

  import Krasukha.OrderBookAgent


  setup do
    {:ok, pid} = start_link()
    [agent: pid]
  end

  test "book_tids/1", %{agent: pid} do
    assert [_,_] = book_tids(pid)
  end

  test "asks_book_tid/1", %{agent: pid} do
    tid = asks_book_tid(pid)
    assert :ordered_set == :ets.info(tid, :type)
    assert :asks == :ets.info(tid, :name)
  end

  test "bids_book_tid/1", %{agent: pid} do
    tid = bids_book_tid(pid)
    assert :ordered_set == :ets.info(tid, :type)
    assert :bids == :ets.info(tid, :name)
  end

  test "stop/1", %{agent: pid} do
    assert :ok == stop(pid)
  end
end
