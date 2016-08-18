defmodule Krasukha.LendingRoutinesTest do
  use ExUnit.Case, async: true

  import Krasukha.LendingRoutines


  test "sleep_time_timeout/1" do
    timeout = sleep_time_timeout(%{sleep_time_inactive: 1, sleep_time_inactive_seed: 1})
    assert timeout == 1001
  end
end
