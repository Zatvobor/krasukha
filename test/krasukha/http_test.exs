defmodule Krasukha.HTTPTest do
  use ExUnit.Case

  import Krasukha.HTTP


  test "uri/0 by default" do
    assert uri() == %URI{authority: "poloniex.com", fragment: nil, host: "poloniex.com", path: nil, port: 443, query: nil, scheme: "https", userinfo: nil}
  end

  test "url/2" do
    assert url("returnLoanOrders", [currency: "BTC"]) == "https://poloniex.com?command=returnLoanOrders&currency=BTC"
  end

  test "url/3" do
    assert url("returnLoanOrders", [currency: "BTC"], %URI{ host: "example.com"}) == "//example.com?command=returnLoanOrders&currency=BTC"
  end
end
