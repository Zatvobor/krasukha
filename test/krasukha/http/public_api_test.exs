defmodule Krasukha.HTTP.PublicAPITest do
  use ExUnit.Case, async: true

  import Krasukha.HTTP.PublicAPI


  test "uri/0 by default" do
    assert uri() == %URI{authority: "poloniex.com", fragment: nil, host: "poloniex.com", path: "/public", port: 443, query: nil, scheme: "https", userinfo: nil}
  end

  test "to_tuple_with_floats/1" do
    assert to_tuple_with_floats(["0.00003575", 663.12507632]) == {3.575e-5, 663.12507632}
    assert to_tuple_with_floats(["10.0", 20]) == {10.0, 20}
  end
end
