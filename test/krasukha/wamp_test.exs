defmodule Krasukha.WAMPTest do
  use ExUnit.Case

  import Krasukha.WAMP


  test "uri/0 by default" do
    assert uri() == %URI{authority: "api.poloniex.com", fragment: nil, host: "api.poloniex.com", path: nil, port: nil, query: nil, scheme: "wss", userinfo: nil}
  end

  test "url/0" do
    assert url() == "wss://api.poloniex.com"
  end
end
