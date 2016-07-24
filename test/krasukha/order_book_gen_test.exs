defmodule Krasukha.OrderBookGenTest do
  use ExUnit.Case, async: true

  alias Krasukha.{OrderBookGen, OrderBookAgent}


  describe "a part of Server/Client API in case of" do
    setup do
      {:ok, pid} = OrderBookGen.start_link("BTC_SC")
      {:ok, [server: pid]}
    end

    test "process is alive", %{server: pid} do
      assert Process.alive?(pid)
    end

    test "order_book is alive", %{server: pid} do
      agent = GenServer.call(pid, :order_book)
      assert Process.alive?(agent)
    end

    test "clean_order_book", %{server: pid} do
      GenServer.call(pid, :clean_order_book)
      assert :ok == GenServer.call(pid, :clean_order_book)
    end

    @tag :external
    test "fetch_order_book", %{server: pid} do
      assert :ok == GenServer.call(pid, {:fetch_order_book, [depth: 1]})

      agent = GenServer.call(pid, :order_book)

      assert 1 == :ets.info(OrderBookAgent.asks_book_tid(agent), :size)
      assert 1 == :ets.info(OrderBookAgent.bids_book_tid(agent), :size)
    end

    test "process terminates", %{server: pid} do
      assert :ok == GenServer.stop(pid)
    end
  end

  test "fetch_order_book/3" do
    {:ok, agent} = OrderBookAgent.start_link()

    asks = [[0.05, 1], [0.06, 1]]
    bids = [[0.04, 1], [0.03, 1]]

    assert :ok == OrderBookGen.fetch_order_book(asks, bids, agent)
    assert 2 == :ets.info(OrderBookAgent.asks_book_tid(agent), :size)
    assert 2 == :ets.info(OrderBookAgent.bids_book_tid(agent), :size)
  end
end
