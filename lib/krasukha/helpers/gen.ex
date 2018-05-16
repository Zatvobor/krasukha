defmodule Krasukha.Helpers.Gen do
  @moduledoc false

  @doc false
  def handle_info({action, identifier}, state) when action in [:suspend, :resume] do
    :ok = apply(:sys, action, [to_pid(identifier)])
    {:noreply, state}
  end

  @doc false
  def handle_call(:do_nothing, _from, state) do
    Krasukha.Helpers.Routine.do_nothing()
    {:reply, :ok, state}
  end

  @doc false
  def to_pid(identifier) when is_binary(identifier), do: :erlang.list_to_pid('<#{identifier}>')
  def to_pid(identifier) when is_list(identifier), do: to_pid(:unicode.characters_to_binary(identifier))

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
