defmodule Krasukha.OrderBookAgent do
  @moduledoc false

  @doc false
  def start_link(prefix \\ "untitled") when is_binary(prefix) do
    book_tids = new_storage(prefix)
    Agent.start_link(fn -> book_tids end)
  end

  @doc false
  defp new_storage(prefix) do
    Enum.map([{:asks, :ordered_set}, {:bids, :ordered_set}, {:history, :set}], fn ({name, type}) ->
      :ets.new(table_name(prefix, name), [type, :protected, :named_table, {:read_concurrency, true}])
    end)
  end

  import String, only: [to_atom: 1]

  defp table_name(prefix, type), do: to_atom("#{String.downcase(prefix)}_#{type}")

  @doc false
  defdelegate stop(agent), to: Agent

  @doc false
  def delete_all_objects(agent), do: Enum.each(tids(agent), fn(tid) -> :true = :ets.delete_all_objects(tid) end)

  @doc false
  def book_tids(agent), do: Agent.get(agent, fn([asks, bids, _]) -> [asks, bids] end)

  @doc false
  def tids(agent), do: Agent.get(agent, fn(state) -> state end)

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

  @doc false
  def history_tid(agent), do: Agent.get(agent, fn([_,_,history_tid]) -> history_tid end)
end
