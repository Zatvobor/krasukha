defmodule Krasukha.Helpers.String do
  @moduledoc false

  defdelegate to_atom(string), to: String


  @doc false
  def to_tuple_with_floats([rate, amount]), do: {to_float(rate), to_float(amount)}
  def to_tuple_with_floats(%{"rate" => rate, "amount" => amount}), do: {to_float(rate), to_float(amount)}
  def to_tuple_with_floats(%{rate: rate, amount: amount, fees: fees}), do: {to_float(rate), to_float(amount), to_float(fees)}
  def to_tuple_with_floats(%{rate: rate, amount: amount}), do: {to_float(rate), to_float(amount)}
  def to_tuple_with_floats(%{"rate" => rate, "type" => type}), do: {to_float(rate), type}

  @doc false
  def to_float(value) when is_binary(value) do
    String.to_float(value)
  rescue
    ArgumentError -> String.to_integer(value)
  end
  def to_float(value), do: value
end
