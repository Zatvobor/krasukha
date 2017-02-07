defmodule Krasukha.WAMPGen do
  use GenServer
  @moduledoc false

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  @doc false
  def init(:ok) do
    state = %{}
    {:ok, state}
  end
end
