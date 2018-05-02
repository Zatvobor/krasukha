require Logger

defmodule Krasukha.Helpers.Routine do
  @moduledoc false

  @doc false
  def satoshi, do: 0.00000001

  @doc false
  def info(term) do
    term |> inspect |> Logger.info
    term
  end

  @doc false
  def do_nothing(_state \\ %{}), do: Logger.info("doing nothing")

  @doc false
  def nz(field) when field in [:infinity], do: field
  def nz(field) when is_integer(field), do: (field / 1)
  def nz(field) when is_float(field), do: field
end
