defmodule Krasukha do
  @moduledoc false

  use Application

  @doc false
  def start(_type \\ nil, _args \\ nil) do
    import Supervisor.Spec, warn: false

    children = []

    opts = [strategy: :one_for_one, name: Krasukha.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
