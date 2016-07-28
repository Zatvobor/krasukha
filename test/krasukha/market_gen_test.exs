defmodule Krasukha.MarketGenTest do
  use ExUnit.Case, async: true

  alias Krasukha.{MarketGen}

  setup do
    {:ok, pid} = MarketGen.start_link("BTC_SC")
    {:ok, [server: pid]}
  end

  describe "a part of order book operations in case of" do
    test "process is alive", %{server: pid} do
      assert Process.alive?(pid)
    end

    test "clean_order_book", %{server: pid} do
      GenServer.call(pid, :clean_order_book)
      assert :ok == GenServer.call(pid, :clean_order_book)
    end

    test "tids", %{server: pid} do
      [asks,bids,history] = GenServer.call(pid, :tids)
      assert asks == :btc_sc_asks
      assert bids == :btc_sc_bids
      assert history == :btc_sc_history
    end

    test "book_tids", %{server: pid} do
      assert [asks,bids] = GenServer.call(pid, :book_tids)
      assert asks == :btc_sc_asks
      assert bids == :btc_sc_bids
    end

    test "asks_book_tid", %{server: pid} do
      tid = GenServer.call(pid, :asks_book_tid)
      assert :ets.info(tid, :name) == :btc_sc_asks
    end

    test "bids_book_tid", %{server: pid} do
      tid = GenServer.call(pid, :bids_book_tid)
      assert :ets.info(tid, :name) == :btc_sc_bids
    end

    test "book_tid/asks", %{server: pid} do
      tid = GenServer.call(pid, {:book_tid, :asks})
      assert :ets.info(tid, :name) == :btc_sc_asks
    end

    test "book_tid/ask", %{server: pid} do
      tid = GenServer.call(pid, {:book_tid, "ask"})
      assert :ets.info(tid, :name) == :btc_sc_asks
    end

    test "book_tid/buy", %{server: pid} do
      tid = GenServer.call(pid, {:book_tid, "buy"})
      assert :ets.info(tid, :name) == :btc_sc_asks
    end

    test "book_tid/bids", %{server: pid} do
      tid = GenServer.call(pid, {:book_tid, :bids})
      assert :ets.info(tid, :name) == :btc_sc_bids
    end

    test "book_tid/bid", %{server: pid} do
      tid = GenServer.call(pid, {:book_tid, "bid"})
      assert :ets.info(tid, :name) == :btc_sc_bids
    end

    test "book_tid/sell", %{server: pid} do
      tid = GenServer.call(pid, {:book_tid, "sell"})
      assert :ets.info(tid, :name) == :btc_sc_bids
    end

    test "history_tid", %{server: pid} do
      tid = GenServer.call(pid, :history_tid)
      assert :ets.info(tid, :name) == :btc_sc_history
    end

    test "process terminates", %{server: pid} do
      assert :ok == GenServer.stop(pid)
    end
  end

  describe "order_book is fetching, using" do
    @tag :external
    test "fetch_order_book", %{server: pid} do
      [asks_book_tid, bids_book_tid] = GenServer.call(pid, :book_tids)
      assert :ok = GenServer.call(pid, {:fetch_order_book, [depth: 1]})
      assert :ets.info(asks_book_tid, :size) == 1
      assert :ets.info(bids_book_tid, :size) == 1
    end

    test "fetch_order_book/3" do
      asks = [["0.05", 1], [0.06, 1]]
      bids = [[0.04, 1], [0.03, "1"]]
      book_tids = MarketGen.__create_books_table()
      %{asks_book_tid: asks_book_tid, bids_book_tid: bids_book_tid} = book_tids

      assert :ok = MarketGen.fetch_order_book(book_tids, asks, bids)
      assert :ets.info(asks_book_tid, :size) == 2
      assert :ets.lookup(asks_book_tid, 0.05) == [{0.05, 1}]
      assert :ets.info(bids_book_tid, :size) == 2
      assert :ets.lookup(bids_book_tid, 0.03) == [{0.03, 1}]
    end
  end

  describe "order_book is updating, in case of 'orderBookModify' type" do
    setup do
      book_tids = MarketGen.__create_books_table()
      {:ok, [book_tids: book_tids]}
    end

    @message [6956793409822983, 4840230496786428, %{},
    [
        %{"data" => %{"amount" => "10.10", "rate" => "0.00000110", "type" => "ask"}, "type" => "orderBookModify"},
        %{"data" => %{"amount" => "20", "rate" => "0.00000111", "type" => "ask"}, "type" => "orderBookModify"}
    ],
        %{"seq" => 733186}
    ]

    test "update_order_book/3 places slots into stack", %{book_tids: %{asks_book_tid: tid}} = state do
      assert :ok = MarketGen.update_order_book(state, @message)

      assert :ets.info(tid, :size) == 2
      assert :ets.lookup(tid, 0.00000110) == [{0.00000110, 10.10}]
    end

    test "update_order_book/3 modifies amount in existing slots", %{book_tids: %{asks_book_tid: tid}} = state do
      assert :true = :ets.insert(tid, {0.00000110, 1})
      assert :ok = MarketGen.update_order_book(state, @message)

      assert :ets.info(tid, :size) == 2
      assert :ets.lookup(tid, 0.00000110) == [{0.00000110, 10.10}]
    end
  end

  describe "order_book is updating, in case of 'orderBookRemove' type" do
    setup do
      book_tids = MarketGen.__create_books_table()
      {:ok, [book_tids: book_tids]}
    end

    @message [6956793409822983, 4840230496786428, %{},
    [
        %{"data" => %{"rate" => "0.00000110", "type" => "bid"}, "type" => "orderBookRemove"}
    ],
        %{"seq" => 733186}
    ]

    test "update_order_book/3 places slots into stack", %{book_tids: %{bids_book_tid: tid}} = state do
      assert :ok = MarketGen.update_order_book(state, @message)

      assert :ets.info(tid, :size) == 0
      assert :ets.lookup(tid, 0.00000110) == []
    end

    test "update_order_book/3 modifies amount in existing slots", %{book_tids: %{bids_book_tid: tid}} = state do
      assert :true = :ets.insert(tid, {0.00000110, 1})
      assert :ok = MarketGen.update_order_book(state, @message)

      assert :ets.info(tid, :size) == 0
      assert :ets.lookup(tid, 0.00000110) == []
    end
  end

  describe "order_book is updating, in case of 'newTrade' type" do
    setup do
      book_tids = MarketGen.__create_books_table()
      history_tid = MarketGen.__create_history_table()
      {:ok, [book_tids: book_tids, history_tid: history_tid]}
    end

    @message [6956793409822983, 4840230496786428, %{},
    [
        %{"data" => %{"tradeID" => 1, "rate" => "0.00000110", "amount" => "10.03", "date" => "2014-10-07 21:51:20", "total" => "0.000011", "type" => "sell"}, "type" => "newTrade"}
    ],
        %{"seq" => 733186}
    ]

    test "update_order_book/3 places slots into stack", %{book_tids: %{bids_book_tid: tid}} = state do
      assert :ok = MarketGen.update_order_book(state, @message)

      assert :ets.info(tid, :size) == 0
      assert :ets.lookup(tid, 0.00000110) == []
    end

    test "update_order_book/3 modifies amount in existing slots", %{book_tids: %{bids_book_tid: tid}} = state do
      assert :true = :ets.insert(tid, {0.00000110, 20.15})
      assert :ok = MarketGen.update_order_book(state, @message)

      assert :ets.info(tid, :size) == 1
      assert :ets.lookup(tid, 0.00000110) == [{0.00000110, 10.12}]
    end
  end
end
