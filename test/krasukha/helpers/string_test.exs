defmodule Krasukha.Helpers.StringTest do
  use ExUnit.Case, async: true

  import Krasukha.Helpers.String


  test "to_tuple_with_floats/1" do
    assert to_tuple_with_floats(["0.00003575", 663.12507632]) == {3.575e-5, 663.12507632}
    assert to_tuple_with_floats(["10.0", 20]) == {10.0, 20}
  end
end
