import Krasukha.Helpers.Routine

defmodule Krasukha.Helpers.RoutineTest do
  use ExUnit.Case, async: true

  test "satoshi/0" do
    assert satoshi == 0.00000001
  end

  test "nz/1" do
    assert nz(:infinity) == :infinity
    assert nz(10) == 10.0
    assert nz(1.0) == 1
  end
end
