alias Krasukha.{SecretAgent, LendingRoutines}

defmodule Krasukha.SecretAgent.Supervisor do
  @moduledoc false

  use Krasukha.Helpers.Supervisor

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
end
