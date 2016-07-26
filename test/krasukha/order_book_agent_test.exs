defmodule Krasukha.OrderBookAgentTest do
  use ExUnit.Case, async: true

  import Krasukha.OrderBookAgent


  setup do
    {:ok, pid} = start_link("BTC_SC")
    [agent: pid]
  end

  test "tids/1", %{agent: pid} do
    assert [asks,bids,history] = tids(pid)
    assert :btc_sc_asks     == asks
    assert :btc_sc_bids     == bids
    assert :btc_sc_history  == history
  end

  test "book_tids/1", %{agent: pid} do
    assert [asks,bids] = book_tids(pid)
    assert :btc_sc_asks     == asks
    assert :btc_sc_bids     == bids
  end

  test "asks_book_tid/1", %{agent: pid} do
    tid = asks_book_tid(pid)
    assert :ordered_set == :ets.info(tid, :type)
    assert :btc_sc_asks == :ets.info(tid, :name)
  end

  test "book_tid(agent, 'ask')", %{agent: pid} do
    tid = book_tid(pid, "ask")
    assert :ordered_set == :ets.info(tid, :type)
    assert :btc_sc_asks == :ets.info(tid, :name)
  end

  test "book_tid(agent, 'buy')", %{agent: pid} do
    tid = book_tid(pid, "buy")
    assert :ordered_set == :ets.info(tid, :type)
    assert :btc_sc_asks == :ets.info(tid, :name)
  end

  test "bids_book_tid/1", %{agent: pid} do
    tid = bids_book_tid(pid)
    assert :ordered_set == :ets.info(tid, :type)
    assert :btc_sc_bids == :ets.info(tid, :name)
  end

  test "book_tid(agent, 'bid')", %{agent: pid} do
    tid = book_tid(pid, "bid")
    assert :ordered_set == :ets.info(tid, :type)
    assert :btc_sc_bids == :ets.info(tid, :name)
  end

  test "book_tid(agent, 'sell')", %{agent: pid} do
    tid = book_tid(pid, "sell")
    assert :ordered_set == :ets.info(tid, :type)
    assert :btc_sc_bids == :ets.info(tid, :name)
  end

  test "history_tid/1", %{agent: pid} do
    tid = history_tid(pid)
    assert :set == :ets.info(tid, :type)
    assert :btc_sc_history == :ets.info(tid, :name)
  end

  test "stop/1", %{agent: pid} do
    assert :ok == stop(pid)
  end
end
