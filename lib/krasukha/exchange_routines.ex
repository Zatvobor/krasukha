defmodule Krasukha.ExchangeRoutines do
  @moduledoc false

  alias Krasukha.{HTTP, Helpers.Naming, Helpers.Routine, Helpers.String}


  @doc false
  def start_link(agent, strategy, params) do
    pid = start(agent, strategy, params)
    :true = Process.link(pid)
    {:ok, pid}
  end

  @doc false
  def start(agent, strategy, params) do
    state = init(agent, params)
    spawn(Routine, :start_routine, [__MODULE__, strategy, state])
  end

  @doc false
  def default_params() do
    Routine.default_params()
  end

  @doc false
  def init(agent, %{currency_pair: currency_pair} = params) do
    default_params()
      |> Map.merge(params)
      |> Map.merge(%{market: Naming.process_name(currency_pair, :market)})
      |> Map.merge(%{agent: agent})
  end
end
