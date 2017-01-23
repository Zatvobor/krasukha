defmodule Krasukha.LendingRoutinesTest do
  use ExUnit.Case, async: true

  alias Krasukha.{LendingGen, LendingRoutines}


  describe "filter_open_loan_offers/2 in context of" do
    setup do
      open_loan_offers = [
        %{date: "2017-01-20 10:39:35"}
      ]
      {:ok, [open_loan_offers: open_loan_offers]}
    end

    test "a", %{open_loan_offers: open_loan_offers} do
      actual = LendingRoutines.filter_open_loan_offers(open_loan_offers, %{after_time_inactive: 10})
      assert length(actual) == 1
    end
    test "b", %{open_loan_offers: open_loan_offers} do
      actual = LendingRoutines.filter_open_loan_offers(open_loan_offers, %{after_time_inactive: 1484923660})
      assert length(actual) == 0
    end
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
