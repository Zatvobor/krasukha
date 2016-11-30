defmodule Krasukha.SecretAgent.Supervisor do
  @moduledoc false


  @doc false
  def to_pid_from_identifier(term) do
    result = for {^term, pid, :worker, [_]} <- Supervisor.which_children(__MODULE__), do: pid
    List.first(result)
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
