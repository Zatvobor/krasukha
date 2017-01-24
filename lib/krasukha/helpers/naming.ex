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

  @doc false
  def split_currency_pair(%{currency_pair: currency_pair}), do: split_currency_pair(currency_pair)
  def split_currency_pair(currency_pair) when is_binary(currency_pair), do: String.split(currency_pair, "_")

  @doc false
  def head_currency_pair(%{currency_pair: currency_pair}) do
    head_currency_pair(currency_pair)
  end
  def head_currency_pair(currency_pair) when is_binary(currency_pair) do
    split_currency_pair(currency_pair)
    |> List.first
  end

  @doc false
  def tail_currency_pair(%{currency_pair: currency_pair}) do
    tail_currency_pair(currency_pair)
  end
  def tail_currency_pair(currency_pair) when is_binary(currency_pair) do
    split_currency_pair(currency_pair)
    |> List.last
  end
end
