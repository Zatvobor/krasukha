defmodule Krasukha.Helpers.EventRoutine do
  @moduledoc false

  @doc false
  def start_routine(parent, state) do
    Process.flag(:trap_exit, true)
    :ok = add_handler(state)
    loop(parent, state)
  end

  @doc false
  def loop(parent, state) when is_pid(parent) do
    receive do
      :start ->
        :ok = add_handler(state)
        loop(parent, state)
      :stop ->
        :ok = remove_handler(state)
      {:adjust, request} ->
        new_state = Enum.into(request, state)
        loop(parent, new_state)
      {:system, from, request} ->
        :sys.handle_system_msg(request, from, parent, __MODULE__, [], [state])
      {:EXIT, _from, reason} when reason in [:normal, :shutdown] ->
        exit(reason)
    end
  end

  @doc false
  def add_handler(%{gen_event: pid, handler: handler} = state) do
    GenEvent.add_handler(pid, handler, state)
  end

  @doc false
  def remove_handler(%{gen_event: pid, handler: handler} = state) do
    GenEvent.remove_handler(pid, handler, state)
  end
end
