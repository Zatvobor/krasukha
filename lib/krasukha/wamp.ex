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
    pid = case Supervisor.which_children(Spell.Peer.Supervisor) do
      [{:undefined, peer, :worker, [Spell.Peer]} | _t] -> peer
      [] -> nil
    end
    %{subscriber: pid}
  end

  @doc false
  defdelegate connect(url \\ url(), options \\ credentials()), to: Spell, as: :connect

  @doc false
  defdelegate disconnect(wamp_pid), to: Spell, as: :close

  @doc false
  def connect!(url \\ url(), options \\ credentials()) do
    :ok = Application.put_env(:spell, :timeout, options[:timeout], [persistent: true])
    connect(url, options)
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
