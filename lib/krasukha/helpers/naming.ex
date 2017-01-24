defmodule Krasukha.Helpers.Naming do
  @moduledoc false

  @doc false
  defdelegate to_atom(string), to: String

  @doc false
  defdelegate downcase(prefix), to: String

  @doc false
  def to_name(prefix, type), do: to_atom("#{downcase(prefix)}_#{type}")

  @doc false
  def process_name(prefix, type), do: to_name(prefix, type)

  @doc false
  def monotonic_id(), do: :erlang.unique_integer([:monotonic])
end
