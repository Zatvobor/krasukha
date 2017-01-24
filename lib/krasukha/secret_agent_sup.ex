alias Krasukha.{SecretAgent, LendingRoutines}

defmodule Krasukha.SecretAgent.Supervisor do
  @moduledoc false

  @doc false
  def to_pid_from_identifier(term) do
    result = for {^term, pid, :worker, [_]} <- Supervisor.which_children(__MODULE__), do: pid
    List.first(result)
  end

  @doc false
  def shutdown_routines(term, reason \\ :normal) do
    SecretAgent.routines(term) |> Enum.map(fn(pid) -> Process.exit(pid, reason) end)
  end

  @doc false
  def terminate_lending_routines(ids) when is_list(ids) do
    for id <- ids, do: LendingRoutines.Supervisor.terminate_child(id)
  end
  def terminate_lending_routines(term) do
    SecretAgent.routines(term) |> terminate_lending_routines()
  end

  @doc false
  def restart_lending_routines(ids) when is_list(ids) do
    for id <- ids, do: LendingRoutines.Supervisor.restart_child(id)
  end
  def restart_lending_routines(term) do
    SecretAgent.routines(term) |> restart_lending_routines()
  end

  @doc false
  def delete_lending_routines(ids) when is_list(ids) do
    for id <- ids, do: LendingRoutines.Supervisor.delete_child(id)
  end
  def delete_lending_routines(term) do
    SecretAgent.routines(term) |> delete_lending_routines()
  end

  @doc false
  def which_children(ids, currency) when is_list(ids) do
    for id <- ids do
      with {:ok, %{start: start}} <- get_childspec(id),
           {_, :start_link, [_, _, %{currency: ^currency}]} <- start, do: id, else: nil
    end
    |> Enum.reject(&(is_nil(&1)))
  end
  def which_children(term, currency) do
    SecretAgent.routines(term) |> which_children(currency)
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
