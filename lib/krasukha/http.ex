alias Krasukha.SecretAgent

defmodule Krasukha.HTTP do
  @moduledoc false

  @doc false
  @uri URI.parse("https://poloniex.com")
  def uri, do: @uri

  @doc false
  def url(%URI{} = uri), do: uri |> to_string

  @doc false
  def url(command, params \\ [], uri \\ uri) do
    uri(command, params, uri)
      |> to_string
  end

  @doc false
  def uri(command, params \\ [], uri \\ uri) do
    query = URI.encode_query([command: command] ++ params)
    %URI{uri | query: query}
  end

  @doc false
  def get(url) when is_binary(url) do
    url = to_charlist(url)
    request(:get, {url, []})
      |> response()
  end

  @doc false
  def post(command, agent, uri), do: post(command, [], agent, uri)
  @doc false
  def post(command, params, agent, uri) do
    url  = to_charlist(url(uri))
    body = URI.encode_query([command: command, nonce: nonce] ++ params)
    key  = to_charlist(SecretAgent.key(agent))
    sign = :erlang.binary_to_list(sign(agent, body))

    request(:post, {url, [{'Key', key}, {'Sign', sign}], 'application/x-www-form-urlencoded', body}, [], [{:body_format, :binary}])
      |> response()
  end

  @doc false
  def nonce do
    # Note: This time is not a monotonically increasing time in the general case.
    :erlang.system_time
  end

  @doc false
  def sign(secret, query) when is_binary(secret) do
    :crypto.hmac(:sha512, secret, query)
      |> Base.encode16(case: :lower)
  end
  def sign(agent, query) when is_pid(agent), do: sign(SecretAgent.secret(agent), query)

  defp request(method, request, http_options \\ [], options \\ []) do
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
  defp response(:ok, status, body), do: { :ok, status, decode(body) }
  defp response(:error, status, body), do: { :error, status, to_string(body) }

  defp decode(json, opts \\ [{:keys, :atoms}]) do
    Poison.Parser.parse!(json, opts)
  end
end
