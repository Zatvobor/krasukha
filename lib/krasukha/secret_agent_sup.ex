defmodule Krasukha.SecretAgent.Supervisor do
  @moduledoc false


  @doc false
  def to_pid_from_identifier(term) do
    result = for {^term, pid, :worker, [Krasukha.SecretAgent]} <- Supervisor.which_children(__MODULE__), do: pid
    List.first(result)
  end
end
