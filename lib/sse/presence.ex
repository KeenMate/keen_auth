defmodule KeenAuth.SSE.Presence do
  @moduledoc """
  Presence tracking for SSE connections.

  Provides a unified API for tracking which users are connected via SSE.
  Two backends are available, selected via configuration:

  - `:local` (default) — uses Elixir `Registry`, single-node only, zero overhead
  - `:distributed` — uses `Phoenix.Tracker` (CRDT), works across clustered nodes

  ## Configuration

      config :keen_auth,
        sse: [
          presence: :local,        # or :distributed
          pubsub: MyApp.PubSub     # required for :distributed
        ]

  ## Examples

      KeenAuth.SSE.Presence.register(42)
      KeenAuth.SSE.Presence.online?(42)
      KeenAuth.SSE.Presence.online_users()
  """

  @callback register(user_id :: integer(), metadata :: map()) :: {:ok, pid()} | {:error, term()}
  @callback unregister(user_id :: integer()) :: :ok
  @callback list_connections(user_id :: integer()) :: [{pid(), map()}]
  @callback online?(user_id :: integer()) :: boolean()
  @callback online_users() :: [integer()]

  @doc "Registers the current process as a connection for the given user."
  @spec register(integer(), map()) :: {:ok, pid()} | {:error, term()}
  def register(user_id, metadata \\ %{}) do
    backend().register(user_id, metadata)
  end

  @doc "Unregisters the current process from the given user's connections."
  @spec unregister(integer()) :: :ok
  def unregister(user_id) do
    backend().unregister(user_id)
  end

  @doc "Lists all active connections for a user. Returns `[{pid, metadata}]`."
  @spec list_connections(integer()) :: [{pid(), map()}]
  def list_connections(user_id) do
    backend().list_connections(user_id)
  end

  @doc "Checks if a user has any active SSE connections."
  @spec online?(integer()) :: boolean()
  def online?(user_id) do
    backend().online?(user_id)
  end

  @doc "Returns a list of all user IDs with active SSE connections."
  @spec online_users() :: [integer()]
  def online_users do
    backend().online_users()
  end

  @doc "Returns the configured presence backend module."
  @spec backend() :: module()
  def backend do
    config = Application.get_env(:keen_auth, :sse, [])

    case Keyword.get(config, :presence, :local) do
      :local -> KeenAuth.SSE.Presence.Local
      :distributed -> KeenAuth.SSE.Presence.Distributed
      module when is_atom(module) -> module
    end
  end
end
