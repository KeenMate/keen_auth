defmodule KeenAuth.SSE.Presence.Local do
  @moduledoc """
  Registry-based presence tracking for single-node deployments.

  Uses Elixir's built-in `Registry` with `:duplicate` keys.
  Each SSE connection registers under the user's ID.
  Connections are automatically cleaned up when the process dies
  (Registry monitors registered PIDs).

  This is the default backend — zero overhead, no heartbeats, no network traffic.
  """

  @behaviour KeenAuth.SSE.Presence

  @impl true
  def register(user_id, metadata \\ %{}) do
    registry = KeenAuth.SSE.Supervisor.registry_name()
    metadata = Map.put(metadata, :connected_at, DateTime.utc_now())

    case Registry.register(registry, user_id, metadata) do
      {:ok, _pid} = ok -> ok
      {:error, _} = error -> error
    end
  end

  @impl true
  def unregister(user_id) do
    registry = KeenAuth.SSE.Supervisor.registry_name()
    Registry.unregister(registry, user_id)
  end

  @impl true
  def list_connections(user_id) do
    registry = KeenAuth.SSE.Supervisor.registry_name()
    Registry.lookup(registry, user_id)
  end

  @impl true
  def online?(user_id) do
    list_connections(user_id) != []
  end

  @impl true
  def online_users do
    registry = KeenAuth.SSE.Supervisor.registry_name()

    Registry.select(registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.uniq()
  end
end
