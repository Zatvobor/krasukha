defmodule Krasukha.OrderBookAgent do
  @moduledoc false

  @doc false
  def start_link do
    Agent.start_link(fn ->
      Enum.map(1..2, fn (_e) ->
        :ets.new(:order_book, [:ordered_set, :protected, {:read_concurrency, true}])
      end)
    end)
  end

  @doc false
  defdelegate stop(agent), to: Agent

  @doc false
  def asks_book_tid(agent), do: Agent.get(agent, fn ([asks_book_tid, _]) -> asks_book_tid end)

  @doc false
  def bids_book_tid(agent), do: Agent.get(agent, fn ([_, bids_book_tid]) -> bids_book_tid end)
end
