defmodule Krasukha.Helpers.EventGenTest do
  use ExUnit.Case, async: true
  use Krasukha.Helpers.EventGen

  describe "event manager helpers" do
    test "calls create_event_manager/1" do
      state = create_event_manager(%{})
      assert state.event_manager
      assert Process.alive?(state.event_manager)
    end
  end
end
