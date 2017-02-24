defmodule Krasukha.Helpers.Gen do
  @moduledoc false

  @doc false
  def handle_info({action, pid}, state) when action in [:suspend, :resume] do
    :ok = suspend_or_resume(pid, action)
    {:noreply, state}
  end

  @doc false
  def suspend_or_resume(identifier, action) when is_binary(identifier) do
    :erlang.list_to_pid('<#{identifier}>')
      |> suspend_or_resume(action)
  end
  def suspend_or_resume(identifier, action) when is_list(identifier) do
    :unicode.characters_to_binary(identifier)
      |> suspend_or_resume(action)
  end
  def suspend_or_resume(pid, action) when is_pid(pid) do
    apply(:sys, action, [pid])
  end

  @doc false
  def apply_preflight_opts(state, [], _mod), do: state
  def apply_preflight_opts(state, [h | t], mod) do
    new_state = case h do
      {function, args} when is_atom(function) -> apply(mod, function, [state, args])
      function when is_atom(function) -> apply(mod, function, [state])
    end
    apply_preflight_opts(new_state, t, mod)
  end
end
