import Krasukha.Helpers.Gen

defmodule Krasukha.Helpers.GenTest do
  use ExUnit.Case, async: true

  test "to_pid/1" do
    assert is_pid(to_pid("0.0.0"))
    assert is_pid(to_pid('0.0.0'))
  end
end
