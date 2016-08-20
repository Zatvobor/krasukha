defmodule Krasukha.LendingRoutinesTest do
  use ExUnit.Case, async: true

  alias Krasukha.{LendingGen, LendingRoutines}


  test "sleep_time_timeout/1" do
    timeout = LendingRoutines.sleep_time_timeout(%{sleep_time_inactive: 1, sleep_time_inactive_seed: 1})
    assert timeout == 1001
  end

  describe "find_offer_object/1 in context of" do
    setup do
      %{orders_tids: %{offers_tid: offers_tid}} = initial_state = LendingGen.__create_loan_orders_tables()
      :true = :ets.insert(offers_tid, [{1},{2},{3}])
      {:ok, _} = LendingGen.start_link("USDT", initial_state)
      {:ok, [currency: "USDT", currency_lending: :usdt_lending, fetch_loan_orders: false, offers_tid: offers_tid]}
    end

    test "gap_top_position as explicit position number", params do
      object = LendingRoutines.find_offer_object(Map.put(params, :gap_top_position, 1))
      assert object == {1}
      object = LendingRoutines.find_offer_object(Map.put(params, :gap_top_position, 2))
      assert object == {2}
      object = LendingRoutines.find_offer_object(Map.put(params, :gap_top_position, 5))
      assert object == {3}
    end

    test "gap_bottom_position as explicit position number", params do
      object = LendingRoutines.find_offer_object(Map.put(params, :gap_bottom_position, 1))
      assert object == {3}
      object = LendingRoutines.find_offer_object(Map.put(params, :gap_bottom_position, 2))
      assert object == {2}
      object = LendingRoutines.find_offer_object(Map.put(params, :gap_bottom_position, 5))
      assert object == {1}
    end
  end
end
