defmodule Krasukha.WAMP do
  @moduledoc false

  @doc false
  @credentials [realm: "realm1", timeout: 3000]
  def credentials, do: @credentials

  @doc false
  @uri URI.parse("wss://api.poloniex.com")
  def uri, do: @uri

  @doc false
  def url, do: uri |> to_string

  @doc false
  def connection do
    Application.get_env(:krasukha, :wamp, %{subscriber: nil, options: nil})
  end

  @doc false
  defdelegate connect(url \\ url(), options \\ credentials()), to: Spell, as: :connect

  @doc false
  defdelegate disconnect(wamp_pid), to: Spell, as: :close

  @doc false
  def connect!(url \\ url(), options \\ credentials()) do
    :ok = Application.put_env(:spell, :timeout, options[:timeout], [persistent: true])

    {:ok, subscriber} = connect(url, options)
    environment = %{subscriber: subscriber, options: options}
    :ok = Application.put_env(:krasukha, :wamp, environment, [persistent: true])

    {:ok , subscriber}
  end

  @doc false
  def disconnect! do
    disconnect(connection().subscriber)
  end

  @doc false
  defdelegate subscribe(subscriber, currency_pair), to: Spell, as: :call_subscribe

  @doc false
  defdelegate unsubscribe(subscriber, subscription), to: Spell, as: :call_unsubscribe

  @doc false
  defdelegate receive_event(subscriber, subscription), to: Spell
end
