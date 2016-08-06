defmodule Krasukha.HTTPTest do
  use ExUnit.Case, async: true

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

  test "nonce/0" do
    [first, second, last] = [nonce(), nonce(), nonce()]
    assert(last > second > first)
  end

  test "sign/2" do
    assert sign("1", "2") == "2283cd93ecd8187a97c30e813207ed1e610dd9ee7d50db44526d5e97378ac20c4b8f8083f20b20619bad3c6e93d4fd5ea201fcd7ba025d501a67803c595a8b05"
  end
end
