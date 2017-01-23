defmodule Krasukha.Helpers.Routine do
  @moduledoc false
  import Krasukha.Helpers.String


  @doc false
  def start_routine(mod, strategy, %{fulfill_immediately: fulfill_immediately} = params) when is_atom(strategy) do
    Process.flag(:trap_exit, true)
    if(fulfill_immediately, do: apply(mod, strategy, [params]))
    loop(mod, strategy, params)
  end

  @doc false
  def loop(mod, strategy, params) when is_atom(strategy) do
    receive do
      {:EXIT, _, reason} when reason in [:normal, :shutdown] -> :ok
    after
      sleep_time_timeout(params) ->
        apply(mod, strategy, [params])
        loop(mod, strategy, params)
    end
  end

  @doc false
  def default_params() do
    %{}
      |> Map.merge(%{fulfill_immediately: false})
      |> Map.merge(%{sleep_time_inactive: 60, sleep_time_inactive_seed: 1}) # in seconds
  end

  @doc false
  def sleep_time_timeout(%{sleep_time_inactive: sleep_time_inactive, sleep_time_inactive_seed: sleep_time_inactive_seed}) do
    (:rand.uniform(sleep_time_inactive_seed) * 1000) + (sleep_time_inactive * 1000) # getting timeout in milliseconds
  end

  @doc false
  def get_account_balance(%{agent: agent, currency: currency}, type) do
    Krasukha.SecretAgent.account_balance!(agent, type)[String.to_atom(currency)]
      |> float_to_binary()
  end
end
