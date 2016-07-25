defmodule Krasukha.OrderBookGenTest do
  use ExUnit.Case, async: true

  alias Krasukha.{OrderBookGen, OrderBookAgent}

  setup do
    {:ok, pid} = OrderBookGen.start_link("BTC_SC")
    {:ok, [server: pid]}
  end

  describe "a part of order book operations in case of" do
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

    test "process terminates", %{server: pid} do
      assert :ok == GenServer.stop(pid)
    end
  end

  describe "order_book is fetching, using" do
    @tag :external
    test "fetch_order_book", %{server: pid} do
      assert :ok == GenServer.call(pid, {:fetch_order_book, [depth: 1]})

      agent = GenServer.call(pid, :order_book)

      assert 1 == :ets.info(OrderBookAgent.asks_book_tid(agent), :size)
      assert 1 == :ets.info(OrderBookAgent.bids_book_tid(agent), :size)
    end

    test "fetch_order_book/3" do
      {:ok, agent} = OrderBookAgent.start_link()

      asks = [["0.05", 1], [0.06, 1]]
      bids = [[0.04, 1], [0.03, "1"]]

      assert :ok == OrderBookGen.fetch_order_book(agent, asks, bids)

      tid = OrderBookAgent.asks_book_tid(agent)
      assert 2 == :ets.info(tid, :size)
      assert [{0.05, 1}] == :ets.lookup(tid, 0.05)

      tid = OrderBookAgent.bids_book_tid(agent)
      assert 2 == :ets.info(tid, :size)
      assert [{0.03, 1}] == :ets.lookup(tid, 0.03)
    end
  end

  describe "order_book is updating, in case of 'orderBookModify' type" do
    setup do
      {:ok, pid} = OrderBookAgent.start_link()
      {:ok, [agent: pid]}
    end

    @message [6956793409822983, 4840230496786428, %{},
    [
        %{"data" => %{"amount" => "10.10", "rate" => "0.00000110", "type" => "ask"}, "type" => "orderBookModify"},
        %{"data" => %{"amount" => "20", "rate" => "0.00000111", "type" => "ask"}, "type" => "orderBookModify"}
    ],
        %{"seq" => 733186}
    ]

    test "update_order_book/3 places slots into stack", %{agent: agent} do
      tid = OrderBookAgent.asks_book_tid(agent)

      assert :ok == OrderBookGen.update_order_book(agent, @message)

      assert 2 == :ets.info(tid, :size)
      assert [{0.00000110, 10.10}] == :ets.lookup(tid, 0.00000110)
    end

    test "update_order_book/3 modifies amount in existing slots", %{agent: agent} do
      tid = OrderBookAgent.asks_book_tid(agent)

      assert :true == :ets.insert(tid, {0.00000110, 1})
      assert :ok == OrderBookGen.update_order_book(agent, @message)

      assert 2 == :ets.info(tid, :size)
      assert [{0.00000110, 10.10}] == :ets.lookup(tid, 0.00000110)
    end
  end

  describe "order_book is updating, in case of 'orderBookRemove' type" do
    setup do
      {:ok, pid} = OrderBookAgent.start_link()
      {:ok, [agent: pid]}
    end

    @message [6956793409822983, 4840230496786428, %{},
    [
        %{"data" => %{"rate" => "0.00000110", "type" => "bid"}, "type" => "orderBookRemove"}
    ],
        %{"seq" => 733186}
    ]

    test "update_order_book/3 places slots into stack", %{agent: agent} do
      tid = OrderBookAgent.bids_book_tid(agent)

      assert :ok == OrderBookGen.update_order_book(agent, @message)

      assert 0 == :ets.info(tid, :size)
      assert [] == :ets.lookup(tid, 0.00000110)
    end

    test "update_order_book/3 modifies amount in existing slots", %{agent: agent} do
      tid = OrderBookAgent.bids_book_tid(agent)

      assert :true == :ets.insert(tid, {0.00000110, 1})
      assert :ok == OrderBookGen.update_order_book(agent, @message)

      assert 0 == :ets.info(tid, :size)
      assert [] == :ets.lookup(tid, 0.00000110)
    end
  end

  describe "order_book is updating, in case of 'newTrade' type" do
    setup do
      {:ok, pid} = OrderBookAgent.start_link()
      {:ok, [agent: pid]}
    end

    @message [6956793409822983, 4840230496786428, %{},
    [
        %{"data" => %{"tradeID" => 1, "rate" => "0.00000110", "amount" => "10.03", "date" => "2014-10-07 21:51:20", "total" => "0.000011", "type" => "sell"}, "type" => "newTrade"}
    ],
        %{"seq" => 733186}
    ]

    test "update_order_book/3 places slots into stack", %{agent: agent} do
      tid = OrderBookAgent.bids_book_tid(agent)

      assert :ok == OrderBookGen.update_order_book(agent, @message)

      assert 0 == :ets.info(tid, :size)
      assert [] == :ets.lookup(tid, 0.00000110)
    end

    test "update_order_book/3 modifies amount in existing slots", %{agent: agent} do
      tid = OrderBookAgent.bids_book_tid(agent)

      assert :true == :ets.insert(tid, {0.00000110, 20.15})
      assert :ok == OrderBookGen.update_order_book(agent, @message)

      assert 1 == :ets.info(tid, :size)
      assert [{0.00000110, 10.12}] == :ets.lookup(tid, 0.00000110)
    end
  end
end
