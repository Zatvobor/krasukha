defmodule Krasukha.WAMP.Subscribed.Supervisor do
  @moduledoc false

  @doc false
  def start_child(spec), do: Supervisor.start_child(__MODULE__, spec)

  @doc false
  def which_children, do: Supervisor.which_children(__MODULE__)

  @doc false
  def whereis, do: Process.whereis(__MODULE__)

  @doc false
  def get_childspec(id), do: :supervisor.get_childspec(__MODULE__, id)

  @doc false
  def get_childrenspec, do: for_each_children_call(&get_childspec/1)


  defp for_each_children_call(fun) do
    for {id, _, :worker, [_]} <- which_children() do
      {:ok, child_spec} = fun.(id)
      child_spec
    end
  end
end
