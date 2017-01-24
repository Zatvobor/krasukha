defmodule Krasukha.Supervisor do
  @moduledoc false

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
      )
    ]
  end

  @doc false
  def options do
    [strategy: :one_for_one, name: Krasukha.Supervisor]
  end

  @doc false
  def start_link do
    Supervisor.start_link(child_spec, options)
  end

  @doc false
  def terminate_child(id), do: Supervisor.terminate_child(__MODULE__, id)
  @doc false
  def restart_child(id), do: Supervisor.restart_child(__MODULE__, id)
  @doc false
  def delete_child(id), do: Supervisor.delete_child(__MODULE__, id)
end
