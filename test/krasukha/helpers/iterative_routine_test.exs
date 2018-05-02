import Krasukha.Helpers.IterativeRoutine

defmodule Krasukha.Helpers.IterativeRoutineTest do
  use ExUnit.Case, async: true

  test "sleep_time_timeout/1" do
    actual = sleep_time_timeout(%{sleep_time_inactive: 1, sleep_time_inactive_seed: 1})
    assert actual == 2000
  end
end
