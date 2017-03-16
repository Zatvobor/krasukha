defmodule Krasukha.Supervisor do
  @moduledoc false

  use Krasukha.Helpers.Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(child_spec, options)
  end

  @doc false
  def child_spec do
    import Supervisor.Spec, only: [supervisor: 3]

    [
      supervisor(
        Supervisor,
        [[], [strategy: :one_for_one, name: Krasukha.SecretAgent.Supervisor]],
        [id: Krasukha.SecretAgent.Supervisor, restart: :permanent]
      ),
      supervisor(
        Supervisor,
        [[], [strategy: :one_for_one, name: Krasukha.LendingRoutines.Supervisor]],
        [id: Krasukha.LendingRoutines.Supervisor, restart: :permanent]
      ),
      supervisor(
        Supervisor,
        [[], [strategy: :one_for_one, name: Krasukha.ExchangeRoutines.Supervisor]],
        [id: Krasukha.ExchangeRoutines.Supervisor, restart: :permanent]
      ),
      supervisor(
        Krasukha.WAMP.Supervisor, [], restart: :permanent
      )
    ]
  end

  @doc false
  def options do
    [strategy: :one_for_one, name: Krasukha.Supervisor]
  end
end
