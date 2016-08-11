defmodule Krasukha.HTTP.PublicAPITest do
  use ExUnit.Case, async: true

  import Krasukha.HTTP.PublicAPI


  test "uri/0 by default" do
    assert uri() == %URI{authority: "poloniex.com", fragment: nil, host: "poloniex.com", path: "/public", port: 443, query: nil, scheme: "https", userinfo: nil}
  end
end
