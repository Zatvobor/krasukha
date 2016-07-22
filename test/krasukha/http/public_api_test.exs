defmodule Krasukha.HTTP.PublicAPITest do
  use ExUnit.Case

  import Krasukha.HTTP.PublicAPI


  test "uri/0 by default" do
    assert uri() == %URI{authority: "poloniex.com", fragment: nil, host: "poloniex.com", path: "/public", port: 443, query: nil, scheme: "https", userinfo: nil}
  end

  test "normalizeReturnOrderBook/1" do
    assert normalizeReturnOrderBook(["0.00003575", 663.12507632]) == [3.575e-5, 663.12507632]
    actual = normalizeReturnOrderBook(%{asks: [["0.00003575", 663.12507632]], bids: [["0.00003554", 66.27588277]], isFrozen: "0", seq: 6260031})
    expected = %{asks: [[3.575e-5, 663.12507632]], bids: [[3.554e-5, 66.27588277]], isFrozen: "0", seq: 6260031}
    assert  actual == expected
  end
end
