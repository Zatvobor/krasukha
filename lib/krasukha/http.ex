defmodule Krasukha.HTTP do
  @moduledoc false

  alias Krasukha.HTTP.PublicAPI

  @doc false
  defdelegate return_order_book(params), to: PublicAPI


  @uri URI.parse("https://poloniex.com")
  @doc false
  def uri, do: @uri

  @doc false
  def url(command, params \\ [], uri \\ uri) do
    query = URI.encode_query([command: command] ++ params)
    %URI{uri | query: query} |> to_string
  end

  @doc false
  def get(url) when is_binary(url), do: do_request(:get, url)


  defp do_request(method, url) do
    url = String.to_char_list(url)
    case method do
      :get -> ( request(method, {url, []}, [], []) |> response() )
    end
  end

  defp request(method, request, http_options, options) do
    :httpc.request(method, request, http_options, options)
  end

  defp response(req) do
    case req do
      {:ok, { {_, status, _}, _, body}} ->
        if round(status / 100) == 4 || round(status / 100) == 5 do
          response(:error, status, body)
        else
          response(:ok, status, body)
        end
      _ -> :error
    end
  end

  defp response(state, status, []), do: { state, status, [] }
  defp response(state, status, body), do: { state, status, decode(body) }

  defp decode(json, opts \\ [{:keys, :atoms}]) do
    Poison.Parser.parse!(json, opts)
  end
end
