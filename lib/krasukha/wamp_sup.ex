defmodule Krasukha.WAMP.Supervisor do
  use Supervisor
  @moduledoc false

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @doc false
  def init(:ok) do
    supervise(child_spec, options)
  end

  @doc false
  def child_spec do
    import Supervisor.Spec, only: [worker: 3, supervisor: 3]
    [
      worker(
        Krasukha.WAMPGen, [], restart: :permanent
      ),
      supervisor(
        Supervisor,
        [[], [strategy: :one_for_one, name: Krasukha.WAMP.Subscribed.Supervisor]],
        [id: Krasukha.WAMP.Subscribed.Supervisor, restart: :permanent]
      )
    ]
  end

  @doc false
  def options, do: [strategy: :rest_for_one]
end
