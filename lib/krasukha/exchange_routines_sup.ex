defmodule Krasukha.ExchangeRoutines.Supervisor do
  @moduledoc false

  @doc false
  def get_childrenspec, do: for_each_children_call(&get_childspec/1)
  @doc false
  def terminate_children, do: for_each_children_call(&terminate_child/1)
  @doc false
  def restart_children, do: for_each_children_call(&restart_child/1)
  @doc false
  def delete_children, do: for_each_children_call(&delete_child/1)

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


  defp for_each_children_call(fun) do
    for {id, _, :worker, [_]} <- which_children(), do: fun.(id)
  end
end
