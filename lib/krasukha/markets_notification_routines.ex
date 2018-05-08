alias Krasukha.{Helpers, MarketsGen}
import Helpers.Routine

defmodule Krasukha.MarketsNotificationRoutines do
  @moduledoc false

  @doc false
  def start_link(agent, params) do
    pid = start(agent, params)
    :true = Process.link(pid)
    {:ok, pid}
  end

  @doc false
  def start(agent, params) do
    state = init(agent, params)
    :proc_lib.spawn(Helpers.EventRoutine, :start_routine, [self(), state])
  end

  @doc false
  def default_params() do
    %{}
      |> Map.merge(%{gen_event: GenServer.call(:markets, :event_manager)})
      |> Map.merge(%{handler: {__MODULE__, Helpers.Naming.monotonic_id()}})
  end

  @doc false
  def init(agent, %{currency_pair: _} = params) do
    params = Map.merge(default_params(), params)
    params
      |> Map.merge(%{agent: agent})
      |> Map.merge(%{type: assert_type(params.type)})
      |> Map.merge(%{indicator: assert_indicator(params.indicator)}) # could be any field from stored object
      |> Map.merge(%{range: nz(params.range)}) # could be value of price
  end

  @doc false
  def assert_type(term) when term in [:crossing, :crossing_down, :cossing_up], do: term
  @doc false
  def assert_indicator(term) do
    MarketsGen.update_ticker_object_spec[term]
    |> Helpers.String.to_integer
  end

  # GenEvent (handler)

  @doc false
  def init(state), do: {:ok, state}

  @doc false
  def handle_event({event, payload}, state), do: {:ok, state}

  @doc false
  def terminate(_reason, _state), do: :ok

  @doc false
  def code_change(_old, state, _extra), do: {:ok, state}
end
