defmodule Krasukha.MarketsGenTest do
  use ExUnit.Case, async: true

  alias Krasukha.{MarketsGen}

  setup do
    {:ok, pid} = MarketsGen.start_link()
    {:ok, [server: pid]}
  end

  describe "a part of markets operations in case of" do
    test "process is alive", %{server: pid} do
      assert Process.alive?(pid)
    end

    test "ticker table is alive", %{server: pid} do
      tid = GenServer.call(pid, :ticker)
      assert :ets.info(tid, :name) == :ticker
    end

    test "clean_ticker", %{server: pid} do
      tid = GenServer.call(pid, :ticker)
      assert :ok = GenServer.call(pid, :clean_ticker)
      assert :ets.info(tid, :size) == 0
    end

    test "process terminates", %{server: pid} do
      assert :ok = GenServer.stop(pid)
    end
  end

  describe "ticker is fetching, using" do
    @tag :external
    test "fetch_ticker", %{server: pid} do
      tid = GenServer.call(pid, :ticker)
      assert :ok = GenServer.call(pid, :fetch_ticker)
      assert :ets.info(tid, :size) > 0
    end

    test "fetch_ticker/2" do
      tid = :ets.new(:ticker, [:set, :protected, {:read_concurrency, true}])
      payload =%{
        "BTC_LTC" =>
          %{"last" => "0.0251", "lowestAsk" => "0.02589999", "highestBid" => "0.0251", "percentChange" => "0.02390438","baseVolume" => "6.16485315", "quoteVolume" => "245.82513926"}
      }
      assert :ok = MarketsGen.fetch_ticker(tid, payload)
      assert :ets.info(tid, :size) == 1
      assert [_] = :ets.lookup(tid, "BTC_LTC")
    end
  end

  describe "ticker is updating, using" do
    @tag :external
    test "subscribe_ticker/unsubscribe_ticker", %{server: pid} do
      assert {:ok, _ticker_subscription} = MarketsGen.call(pid, :subscribe_ticker)
      assert :ok = MarketsGen.call(pid, :unsubscribe_ticker)
    end

    @message [6956793409822983, 4840230496786428, %{},
      ["BTC_BBR","0.00069501","0.00074346","0.00069501","-0.00742634","8.63286802","11983.47150109",0,"0.00107920","0.00045422"]
    ]

    test "broadcast :ticker subscription event", %{server: pid} do
      send(pid, {__MODULE__, self(), %{args: @message}})
      refute_receive :bye
    end

    test "update_ticker/2" do
      tid = :ets.new(:ticker, [:set, :protected, {:read_concurrency, true}])
      assert :ok = MarketsGen.update_ticker(tid, @message)
      assert :ets.info(tid, :size) == 1
      assert [_] = :ets.lookup(tid, "BTC_BBR")
    end
  end
end
