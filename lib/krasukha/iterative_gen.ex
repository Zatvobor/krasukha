import Krasukha.Helpers.Gen

defmodule Krasukha.IterativeGen do
  use GenServer

  @moduledoc false

  @doc false
  def start_link(params, preflight_opts \\ []) do
    GenServer.start_link(__MODULE__, [params, preflight_opts])
  end

  @doc false
  def default_params() do
    %{timeout: 5000, every: 60} # in seconds
  end

  @doc false
  def init([%{server: _, request: _} = params, preflight_opts]) do
    state = Map.merge(default_params(), params)
    # applies preflight setup
    state = apply_preflight_opts(state, preflight_opts, __MODULE__)

    {:ok, state}
  end

  # GenServer (callbacks)

  @doc false
  def handle_call(:start, _from, state) do
    new_state = iterate(state)
    {:reply, :ok, new_state}
  end
  @doc false
  def handle_call(:stop, _from, %{iterator: pid} = state) do
    Process.exit(pid, :normal)
    {:reply, :ok, Map.delete(state, :iterator)}
  end


  @doc false
  def iterate(%{server: server, request: request, timeout: timeout, every: seconds} = state) do
    pid = :proc_lib.spawn_link(__MODULE__, :loop, [self(), server, request, timeout, seconds * 1000])
    Map.merge(state, %{iterator: pid})
  end

  @doc false
  def loop(parent, server, request, timeout, seconds) do
    Process.flag(:trap_exit, true)
    ref = Process.monitor(server)
    :ok = loop(parent, ref, server, request, timeout, seconds)
    Process.demonitor(ref)
  end

  @doc false
  def loop(parent, ref, server, request, timeout, seconds) do
    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
      {:EXIT, ^parent, _}    -> :ok
    after
      seconds ->
        GenServer.call(server, request, timeout)
        loop(parent, ref, server, request, timeout, seconds)
    end
  end
end
