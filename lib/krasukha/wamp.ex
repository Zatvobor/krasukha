defmodule Krasukha.WAMP do
  @moduledoc false

  @credentials [realm: "realm1", timeout: 3000]
  @doc false
  def credentials, do: @credentials

  @uri URI.parse("wss://api.poloniex.com")
  @doc false
  def uri, do: @uri

  @doc false
  def url, do: uri |> to_string

  @doc false
  def connection do
    Application.get_env(:krasukha, :wamp, %{subscriber: nil, options: nil})
  end

  @doc false
  def connect(options \\ credentials) do
    Spell.connect(url, options)
  end

  @doc false
  def disconect(wamp_pid) do
    Spell.close(wamp_pid)
  end

  @doc false
  def connect!(options \\ credentials) do
    {:ok, subscriber} = connect(options)
    environment = %{subscriber: subscriber, options: options}
    :ok = Application.put_env(:krasukha, :wamp, environment, [persistent: true])

    {:ok , subscriber}
  end

  @doc false
  def disconnect! do
    disconect(connection().subscriber)
  end
end
