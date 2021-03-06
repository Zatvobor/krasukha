import Krasukha.WAMP

defmodule Krasukha.WAMPTest do
  use ExUnit.Case, async: true

  test "uri/0 by default" do
    assert uri() == %URI{authority: "api.poloniex.com", fragment: nil, host: "api.poloniex.com", path: nil, port: nil, query: nil, scheme: "wss", userinfo: nil}
  end

  test "url/0", do: assert url()
  test "credentials/0", do: assert credentials()

  test "connection which doesn't exist" do
    assert %{subscriber: nil} = connection()
  end

  describe "Connection to Push API" do
    @tag [external: true]
    test "connect/0 and disconnect/1" do
      {:ok, pid} = connect()
      assert :ok == disconnect(pid)
    end

    @tag [external: true]
    test "connect!/0 and disconnect!/0" do
      assert {:ok, pid} = connect!()
      assert %{subscriber: ^pid} = connection()
      assert :ok = disconnect!()
    end
  end
end
