alias Krasukha.HTTP
import Krasukha.HTTP.PublicAPI

defmodule Krasukha.HTTP.PublicAPITest do
  use ExUnit.Case, async: true

  test "uri/0 by default" do
    assert uri() == %URI{authority: "poloniex.com", fragment: nil, host: "poloniex.com", path: "/public", port: 443, query: nil, scheme: "https", userinfo: nil}
  end

  test "url/3" do
    assert HTTP.url("returnTicker", [], uri) == "https://poloniex.com/public?command=returnTicker"
  end
end
