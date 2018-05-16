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
    import Supervisor.Spec, only: [worker: 3]
    [
      worker(
        Krasukha.WAMPGen,
        [Krasukha.WAMPGen.env_specific_preflight_opts()],
        [restart: :permanent]
      )
    ]
  end

  @doc false
  def options, do: [strategy: :rest_for_one]
end
