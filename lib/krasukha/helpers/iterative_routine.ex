require Logger

defmodule Krasukha.Helpers.IterativeRoutine do
  @moduledoc false

  @doc false
  def start_routine(parent, mod, strategy, params) when is_atom(strategy) do
    Process.flag(:trap_exit, true)
    loop(mod, strategy, params, parent)
  end

  @doc false
  def loop(mod, strategy, params, parent) when is_atom(strategy) and is_pid(parent) do
    receive do
      :fulfill_immediately ->
        call(mod, strategy, params, parent)
      {:adjust, request} ->
        loop(mod, strategy, Enum.into(request, params), parent)
      {:system, from, request} ->
        :sys.handle_system_msg(request, from, parent, __MODULE__, [], [mod, strategy, params])
      {:EXIT, _from, reason} when reason in [:normal, :shutdown] ->
        exit(reason)
    after
      sleep_time_timeout(params) ->
        call(mod, strategy, params, parent)
    end
  end

  @doc false
  def call(mod, strategy, params, parent) do
    Logger.info "entering into #{mod}.#{strategy}/1 strategy"
    Logger.debug "> its strategy has #{inspect(params)} params"
    case apply(mod, strategy, [params]) do
      {:exit, reason}          -> reason
      state when is_map(state) -> loop(mod, strategy, state, parent)
      _                        -> loop(mod, strategy, params, parent)
    end
  end

  @doc false
  def default_params() do
    %{}
      |> Map.merge(%{sleep_time_inactive: 60, sleep_time_inactive_seed: 1}) # in seconds
  end

  @doc false
  def sleep_time_timeout(%{sleep_time_inactive: sleep_time_inactive, sleep_time_inactive_seed: sleep_time_inactive_seed}) do
    (:rand.uniform(sleep_time_inactive_seed) * 1000) + (sleep_time_inactive * 1000) # getting timeout in milliseconds
  end

  @doc false
  def system_continue(parent, _debug, [mod, strategy, params]) do
    loop(mod, strategy, params, parent)
  end

  @doc false
  def system_get_state([_mod, _strategy, params]) do
    {:ok, params}
  end

  @doc false
  def system_terminate(reason, _parent, _debug, _chs) do
    exit(reason)
  end
end
