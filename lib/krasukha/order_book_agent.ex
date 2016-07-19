defmodule Krasukha.OrderBookAgent do
  @moduledoc false

  @doc false
  def start_link(book_tids \\ nil) do
    Agent.start_link(fn ->
      if book_tids == nil, do: new_storage(), else: book_tids
    end)
  end

  @doc false
  def new_storage do
    Enum.map(1..2, fn (_e) ->
      :ets.new(:order_book, [:ordered_set, :protected, {:read_concurrency, true}])
    end)
  end

  @doc false
  defdelegate stop(agent), to: Agent

  @doc false
  def book_tids(agent), do: Agent.get(agent, fn(book_tids) -> book_tids end)

  @doc false
  def asks_book_tid(agent) do
    [asks_book_tid, _] = book_tids(agent)
    asks_book_tid
  end

  @doc false
  def bids_book_tid(agent) do
    [_, bids_book_tid] = book_tids(agent)
    bids_book_tid
  end
end
