defmodule Krasukha.Helpers.String do
  @moduledoc false

  @doc false
  defdelegate to_atom(string), to: String

  @doc false
  def to_integer(term) when is_integer(term), do: term
  defdelegate to_integer(string), to: String


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
    ArgumentError -> to_float(String.to_integer(value))
  end
  def to_float(value) when is_float(value), do: value
  def to_float(value) when is_integer(value), do: value / 1
  def to_float(nil), do: nil

  @doc false
  def float_to_binary(nil), do: nil
  def float_to_binary(float), do: :erlang.float_to_binary(float, [{:decimals, 8}])

  @doc false
  def to_erl_datetime(<<year::4-bytes, ?-, month::2-bytes, ?-, day::2-bytes, sep, hour::2-bytes, ?:, min::2-bytes, ?:, sec::2-bytes, rest::binary>>) when sep in [?\s, ?T] do
    with {year, ""}       <- Integer.parse(year),
         {month, ""}      <- Integer.parse(month),
         {day, ""}        <- Integer.parse(day),
         {hour, ""}       <- Integer.parse(hour),
         {min, ""}        <- Integer.parse(min),
         {sec, ""}        <- Integer.parse(sec),
         {_microsec, rest} <- Calendar.ISO.parse_microsecond(rest),
         {_offset, ""}    <- Calendar.ISO.parse_offset(rest) do
      {{year, month, day}, {hour, min, sec}}
    else
      _ -> {:error, :invalid_format}
    end
  end

  @doc false
  def now_to_erl_datetime do
    :calendar.now_to_universal_time(:erlang.timestamp())
  end

  @doc false
  def from_erl_datetime({{year, month, day}, {hour, min, sec}}) do
    "#{date_to_string(year, month, day)} #{time_to_string(hour, min, sec)}"
  end

  defp date_to_string(year, month, day) do
    zero_pad(year, 4) <> "-" <> zero_pad(month, 2) <> "-" <> zero_pad(day, 2)
  end

  defp time_to_string(hour, minute, second) do
    zero_pad(hour, 2) <> ":" <> zero_pad(minute, 2) <> ":" <> zero_pad(second, 2)
  end

  defp zero_pad(val, count) do
    num = Integer.to_string(val)
    :binary.copy("0", count - byte_size(num)) <> num
  end


  @doc false
  @epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
  def to_unix_time({{_year, _month, _day}, {_hour, _min, _sec}} = datetime) do
    datetime
      |> :calendar.datetime_to_gregorian_seconds
      |> Kernel.-(@epoch)
  end
  def to_unix_time(%NaiveDateTime{} = dt) do
    to_unix_time({{dt.year, dt.month, dt.day}, {dt.hour, dt.minute, dt.second}})
  end

  @doc false
  def from_unix_time(seconds) do
    {days, time} = :calendar.seconds_to_daystime(seconds)
    {years, month, day} = :calendar.gregorian_days_to_date(days)
    {{1970 + years, month, day}, time}
  end

  @doc false
  def now_to_unix_time() do
    to_unix_time(now_to_erl_datetime())
  end
end
