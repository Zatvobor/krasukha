alias Krasukha.{IterativeGen}

defmodule Krasukha.IterativeGenTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, pid} = IterativeGen.start_link(%{server: :untitled, request: :empty})
    {:ok, [server: pid]}
  end

  describe "server behavior" do
    test "process is alive", %{server: pid} do
      assert Process.alive?(pid)
    end

    test "process terminates", %{server: pid} do
      assert :ok == GenServer.stop(pid)
    end
  end
end
