defmodule Krasukha.OrderBookAgent do
  @moduledoc false

  @doc false
  def start_link(book_tids \\ new_storage()) do
    Agent.start_link(fn -> book_tids end)
  end

  @doc false
  def new_storage do
    Enum.map([:asks, :bids], fn (type) ->
      :ets.new(type, [:ordered_set, :protected, {:read_concurrency, true}])
    end)
  end

  @doc false
  defdelegate stop(agent), to: Agent

  @doc false
  def delete_all_objects(agent), do: Enum.each(book_tids(agent), fn(tid) -> :true = :ets.delete_all_objects(tid) end)

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

  @doc false
  def book_tid(agent, :asks), do: asks_book_tid(agent)
  def book_tid(agent, "ask"), do: asks_book_tid(agent)
  def book_tid(agent, "buy"), do: asks_book_tid(agent)

  @doc false
  def book_tid(agent, :bids), do: bids_book_tid(agent)
  def book_tid(agent, "bid"), do: bids_book_tid(agent)
  def book_tid(agent, "sell"), do: bids_book_tid(agent)
end
