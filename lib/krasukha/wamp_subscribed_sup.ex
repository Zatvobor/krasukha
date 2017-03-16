defmodule Krasukha.WAMP.Subscribed.Supervisor do
  @moduledoc false

  use Krasukha.Helpers.Supervisor

  @doc false
  def start_child(spec), do: Supervisor.start_child(__MODULE__, spec)
end
