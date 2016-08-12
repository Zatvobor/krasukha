defmodule Krasukha.Helpers.Naming do
  @moduledoc false

  defdelegate to_atom(string), to: String
  defdelegate downcase(prefix), to: String


  @doc false
  def to_name(prefix, type), do: to_atom("#{downcase(prefix)}_#{type}")

  @doc false
  def process_name(prefix, type), do: to_name(prefix, type)
end
