defmodule Krasukha.MarketsGenTest do
  use ExUnit.Case, async: true

  alias Krasukha.{MarketsGen, WAMP}

  setup do
    {:ok, pid} = MarketsGen.start_link()
    {:ok, [server: pid]}
  end

  describe "server behavior" do
    test "process is alive", %{server: pid} do
      assert Process.alive?(pid)
    end

    test "process terminates", %{server: pid} do
      assert :ok = GenServer.stop(pid)
    end
  end

  describe "event manager" do
    test "event_manager", %{server: pid} do
      event_manager = GenServer.call(pid, :event_manager)
      assert Process.alive?(event_manager)
    end
  end

  describe "a part of markets operations in case of" do
    test "ticker table is alive", %{server: pid} do
      tid = GenServer.call(pid, :ticker)
      assert :ets.info(tid, :name) == :ticker
    end

    test "clean_ticker", %{server: pid} do
      tid = GenServer.call(pid, :ticker)
      assert :ok = GenServer.call(pid, :clean_ticker)
      assert :ets.info(tid, :size) == 0
    end
  end

  describe "ticker is fetching, using" do
    @tag :external
    test "fetch_ticker", %{server: pid} do
      tid = GenServer.call(pid, :ticker)
      assert :ok = GenServer.call(pid, :fetch_ticker)
      assert :ets.info(tid, :size) > 0
    end

    @payload %{ "BTC_LTC" => %{"last" => "0.0251", "lowestAsk" => "0.02589999", "highestBid" => "0.0251", "percentChange" => "0.02390438","baseVolume" => "6.16485315", "quoteVolume" => "245.82513926"} }

    test "fetch_ticker/2 saves into :ets" do
      %{ticker: tid} = state = MarketsGen.__create_ticker_table()
      assert :ok = MarketsGen.fetch_ticker(state, @payload)
      assert :ets.info(tid, :size) == 1
      assert [_] = :ets.lookup(tid, :BTC_LTC)
    end

    test "fetch_ticker/2 notifies over GenEvent" do
      state = %{}
        |> Map.merge(MarketsGen.__create_ticker_table())
        |> Map.merge(MarketsGen.__create_gen_event())

      %{event_manager: event_manager} = state
      assert :ok = GenEvent.add_handler(event_manager, EventHandler, [self()])

      assert :ok = MarketsGen.fetch_ticker(state, @payload)
      assert_receive {:fetch_ticker, {:BTC_LTC, 6.16485315, 0.0251, 0.0251, 0.02589999, 0.02390438, 245.82513926}}
    end
  end

  describe "ticker is updating, using" do
    @tag :external
    test "subscribe_ticker/unsubscribe_ticker", %{server: pid} do
      assert {:ok, subscriber} = WAMP.connect()
      assert :ok = GenServer.call(pid, {:subscriber, subscriber})
      assert {:ok, _ticker_subscription} = GenServer.call(pid, :subscribe_ticker)
      assert :ok = GenServer.call(pid, :unsubscribe_ticker)
      assert :ok = WAMP.disconnect(subscriber)
    end

    @message [6956793409822983, 4840230496786428, %{},
      ["BTC_BBR","0.00069501","0.00074346","0.00069501","-0.00742634","8.63286802","11983.47150109",0,"0.00107920","0.00045422"]
    ]

    test "broadcast :ticker subscription event", %{server: pid} do
      send(pid, {__MODULE__, self(), %{args: @message}})
      refute_receive :bye
    end

    test "update_ticker/2 saves into :est" do
      %{ticker: tid} = state = MarketsGen.__create_ticker_table()
      assert :ok = MarketsGen.update_ticker(state, @message)
      assert :ets.info(tid, :size) == 1
      assert [_] = :ets.lookup(tid, :BTC_BBR)
    end

    test "update_ticker/2 notifies over GenEvent" do
      state = %{}
        |> Map.merge(MarketsGen.__create_ticker_table())
        |> Map.merge(MarketsGen.__create_gen_event())

      %{event_manager: event_manager} = state
      assert :ok = GenEvent.add_handler(event_manager, EventHandler, [self()])

      assert :ok = MarketsGen.update_ticker(state, @message)
      assert_receive {:update_ticker, {:BTC_BBR, 6.9501e-4, 7.4346e-4, 6.9501e-4, -0.00742634, 8.63286802, 11983.47150109, 0, 0.0010792, 4.5422e-4}}
    end
  end
end
