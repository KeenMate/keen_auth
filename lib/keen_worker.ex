defmodule KeenAuth.KeenWorker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: )
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  # TODO: Handle registration of new tokens
  # TODO: Handle retrieval of tokens
  # TODO: Handle refreshing token when expired token is accessed
end
