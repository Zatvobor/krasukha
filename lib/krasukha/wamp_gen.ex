alias Krasukha.{WAMP}

defmodule Krasukha.WAMPGen do
  use GenServer
  @moduledoc false

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @doc false
  def init(:ok) do
    # inject available connection and defaults
    state = %{wamp_subscribed: nil}
      |> Map.merge(WAMP.connection)
    # fetch subscribed specs which were available before crash
    if specs = Application.get_env(:krasukha, :wamp_subscribed) do
      {:ok, %{state | wamp_subscribed: specs}, 500}
    else
      {:ok, state}
    end
  end

  @doc false
  def handle_call(:connect, _from, %{subscriber: nil} = state) do
    new_state = connect(state)
    {:reply, {:ok, new_state.subscriber}, new_state}
  end

  @doc false
  def handle_call(:disconnect, _from, %{subscriber: pid} = state) when is_pid(pid) do
    new_state = disconnect(state)
    {:reply, :ok, new_state}
  end

  @doc false
  def handle_info({Spell.Peer, _from, {:error, reason}}, state) do
    {:stop, :error, reason, state}
  end

  @doc false
  def handle_info({Spell.Transport.WebSocket, _from, {:terminating, {:remote, :closed} = reason}}, state) do
    {:stop, :error, reason, state}
  end

  @doc false
  def handle_info({Spell.Peer, _from, {:closed, :goodbye}}, state) do
    {:noreply, state}
  end

  @doc false
  def handle_info(:timeout, %{wamp_subscribed: specs}= state) when is_list(specs) do
    if WAMP.Subscribed.Supervisor.whereis() do
      for spec <- specs, do: {:ok, _pid} = WAMP.Subscribed.Supervisor.start_child(spec)
      :ok = Application.delete_env(:krasukha, :wamp_subscribed, [persistent: true])
      {:noreply, %{state | wamp_subscribed: nil}}
    else
      {:noreply, state, 500}
    end
  end

  @doc false
  def terminate(_reason, _state) do
    with pid when is_pid(pid) <- WAMP.Subscribed.Supervisor.whereis(),
      specs when length(specs) > 0 <- WAMP.Subscribed.Supervisor.get_childrenspec() do
        :ok = Application.put_env(:krasukha, :wamp_subscribed, specs, [persistent: true])
      end
  end

  defp connect(state) do
    {:ok, pid} = WAMP.connect!
    %{state | subscriber: pid}
  end

  defp disconnect(%{subscriber: pid} = state) do
    :ok = WAMP.disconnect(pid)
    %{state | subscriber: nil}
  end
end