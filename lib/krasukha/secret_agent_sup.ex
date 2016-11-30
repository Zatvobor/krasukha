defmodule Krasukha.SecretAgent.Supervisor do
  @moduledoc false


  @doc false
  def to_pid_from_identifier(term) do
    result = for {^term, pid, :worker, [_]} <- Supervisor.which_children(__MODULE__), do: pid
    List.first(result)
  end

  @doc false
  def terminate_lending_routines(agent) when is_pid(agent) do
    Krasukha.SecretAgent.routines(agent) |> terminate_lending_routines()
  end
  def terminate_lending_routines(ids) when is_list(ids) do
    for id <- ids, do: Krasukha.LendingRoutines.Supervisor.terminate_child(id)
  end
  def terminate_lending_routines(term) do
    term |> to_pid_from_identifier() |> terminate_lending_routines()
  end

  @doc false
  def restart_lending_routines(agent) when is_pid(agent) do
    Krasukha.SecretAgent.routines(agent) |> restart_lending_routines()
  end
  def restart_lending_routines(ids) when is_list(ids) do
    for id <- ids, do: Krasukha.LendingRoutines.Supervisor.restart_child(id)
  end
  def restart_lending_routines(term) do
    term |> to_pid_from_identifier() |> restart_lending_routines()
  end

  @doc false
  def delete_lending_routines(agent) when is_pid(agent) do
    Krasukha.SecretAgent.routines(agent) |> delete_lending_routines()
  end
  def delete_lending_routines(ids) when is_list(ids) do
    for id <- ids, do: Krasukha.LendingRoutines.Supervisor.delete_child(id)
  end
  def delete_lending_routines(term) do
    term |> to_pid_from_identifier() |> delete_lending_routines()
  end

  @doc false
  def which_children, do: Supervisor.which_children(__MODULE__)
  @doc false
  def count_children, do: Supervisor.count_children(__MODULE__)
  @doc false
  def get_childspec(id), do: :supervisor.get_childspec(__MODULE__, id)
  @doc false
  def terminate_child(id), do: Supervisor.terminate_child(__MODULE__, id)
  @doc false
  def restart_child(id), do: Supervisor.restart_child(__MODULE__, id)
  @doc false
  def delete_child(id), do: Supervisor.delete_child(__MODULE__, id)
end
