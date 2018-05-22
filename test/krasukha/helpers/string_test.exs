import Krasukha.Helpers.String

defmodule Krasukha.Helpers.StringTest do
  use ExUnit.Case, async: true

  test "to_tuple_with_floats/1" do
    assert to_tuple_with_floats(["0.00003575", 663.12507632]) == {3.575e-5, 663.12507632}
    assert to_tuple_with_floats(["10.0", 20]) == {10.0, 20}
  end

  test "float_to_binary/1" do
    assert float_to_binary(0.10) == "0.10000000"
    assert float_to_binary(0.00003575) == "0.00003575"
  end

  test "to_erl_datetime/1" do
    assert to_erl_datetime("2017-01-20 10:39:35") == {{2017, 1, 20}, {10, 39, 35}}
  end

  test "from_erl_datetime/1" do
    assert from_erl_datetime({{2017, 1, 20}, {10, 39, 35}}) == "2017-01-20 10:39:35"
  end

  test "to_unix_time/1" do
    assert to_unix_time({{1970, 1, 1}, {0, 0, 0}}) == 0
    assert to_unix_time({{2017, 1, 20}, {10, 39, 35}}) == 1484908775
    assert to_unix_time(NaiveDateTime.from_iso8601!("2014-02-10 04:23:23")) == 1392006203
  end

  test "from_unix_time/1" do
    assert from_unix_time(0) == {{1970, 1, 1}, {0, 0, 0}}
    assert from_unix_time(1484908775) == {{2017, 1, 20}, {10, 39, 35}}
  end

  test "now_to_unix_time/0" do
    assert now_to_unix_time >= 1484923660
  end
end
