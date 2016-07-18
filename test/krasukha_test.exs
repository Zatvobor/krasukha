defmodule KrasukhaTest do
  use ExUnit.Case

  doctest Krasukha

  setup_all do
    :ok = Application.ensure_started(:krasukha)
  end


  test "the truth" do
    assert 1 + 1 == 2
  end
end
