defmodule Krasukha.LendingGenTest do
  use ExUnit.Case, async: true

  alias Krasukha.{LendingGen}


  setup do
    {:ok, pid} = LendingGen.start_link("BTC")
    {:ok, [server: pid]}
  end

  describe "server behavior" do
    test "process is alive", %{server: pid} do
      assert Process.alive?(pid)
      assert is_pid(Process.whereis(:btc_lending))
    end

    test "process terminates", %{server: pid} do
      assert :ok == GenServer.stop(pid)
    end
  end

  describe "a part of lending orders operations in case of" do
    test "clean_loan_offers", %{server: pid} do
      assert :ok = GenServer.call(pid, :clean_loan_offers)
    end
    test "clean_loan_demands", %{server: pid} do
      assert :ok = GenServer.call(pid, :clean_loan_demands)
    end
    test "offers_tid", %{server: pid} do
      tid = GenServer.call(pid, :offers_tid)
      assert :ets.info(tid, :name) == :btc_loan_offers
    end
    test "demands_tid", %{server: pid} do
      tid = GenServer.call(pid, :demands_tid)
      assert :ets.info(tid, :name) == :btc_loan_demands
    end
    test "orders_tids", %{server: pid} do
      [offers_tid, demands_tid] = GenServer.call(pid, :orders_tids)
      assert :ets.info(offers_tid, :name) == :btc_loan_offers
      assert :ets.info(demands_tid, :name) == :btc_loan_demands
    end
    test "clean_loan_orders", %{server: pid} do
      [offers_tid, demands_tid] = GenServer.call(pid, :orders_tids)
      assert :ok = GenServer.call(pid, :clean_loan_orders)
      assert :ets.info(offers_tid, :size) == 0
      assert :ets.info(demands_tid, :size) == 0
    end
  end

  describe "loan_orders is fetching, using" do
    @tag :external
    test "fetch_loan_orders", %{server: pid} do
      offers_tid = GenServer.call(pid, :offers_tid)
      assert :ok = GenServer.call(pid, :fetch_loan_orders)
      assert :ets.info(offers_tid, :size) > 1
    end

    @payload %{
      demands: [%{amount: "0.23250365", rangeMax: 2, rangeMin: 2, rate: "0.00018000"}],
      offers: [%{amount: "0.00536505", rangeMax: 2, rangeMin: 2, rate: "0.00022000"}]
    }
    test "fetch_loan_orders/2 and inserting object into :ets" do
      %{orders_tids: orders_tids} = state = LendingGen.__create_loan_orders_tables()
      %{offers_tid: offers_tid, demands_tid: demands_tid} = orders_tids

      assert :ok = LendingGen.fetch_loan_orders(state, @payload.offers, @payload.demands)
      assert :ets.info(offers_tid, :size) == 1
      assert :ets.lookup(offers_tid, 2.2e-4) == [{2.2e-4, 0.00536505, 2, 2}]
      assert :ets.info(demands_tid, :size) == 1
      assert :ets.lookup(demands_tid, 1.8e-4) == [{1.8e-4, 0.23250365, 2, 2}]
    end
  end

  @tag :skip
  describe "loan_orders is updating, using" do
  end

  @tag :skip # @tag [external: true]
  test "update_loan_orders/2"

  @tag :skip # @tag [external: true]
  test "stop_to_update_loan_orders/0"
end
