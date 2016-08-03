defmodule Krasukha.SecretAgent do
  @moduledoc false


  @doc false
  def start_link(key, secret) do
    Agent.start_link(fn -> %{key: key, secret: secret} end)
  end

  @doc false
  def key(agent), do: Agent.get(agent, fn(%{key: k}) -> k end)

  @doc false
  def secret(agent), do: Agent.get(agent, fn(%{secret: s}) -> s end)

  @doc false
  def key_and_secret(agent), do: Agent.get(agent, fn(%{key: k, secret: s}) -> {k,s} end)
end
