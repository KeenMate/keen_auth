defmodule KeenAuth.SSE.MembershipCache do
  @moduledoc """
  ETS-based in-memory cache of user memberships for SSE event routing.

  Tracks which groups, tenants, and providers each connected user belongs to.
  This data is used for resolving affected users when DELETE events arrive
  from PostgreSQL (the cascade has already removed the rows by the time
  the notification reaches the backend).

  ## Lifecycle

  - **Populated** when a user connects via SSE (`track/2`)
  - **Updated** when membership data changes (`update/2`)
  - **Cleaned up** when user disconnects (`untrack/1`)

  ## Data Structure

  Each user entry stores:

      %{
        user_id: integer(),
        group_ids: MapSet.t(integer()),
        tenant_ids: MapSet.t(integer()),
        provider_codes: MapSet.t(String.t())
      }

  ## Usage

      # When user connects via SSE
      MembershipCache.track(user_id, %{
        group_ids: [1, 2, 3],
        tenant_ids: [1],
        provider_codes: ["entra"]
      })

      # Resolve users in a group (for delete events)
      MembershipCache.users_in_group(group_id)

      # Clean up on disconnect
      MembershipCache.untrack(user_id)
  """

  use GenServer

  @table __MODULE__

  # ============================================================================
  # Public API
  # ============================================================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Tracks a user's memberships when they connect via SSE.

  `memberships` is a map with optional keys:
  - `:group_ids` — list of group IDs the user belongs to
  - `:tenant_ids` — list of tenant IDs the user has access to
  - `:provider_codes` — list of auth provider codes the user uses
  """
  @spec track(integer(), map()) :: :ok
  def track(user_id, memberships \\ %{}) do
    entry = %{
      user_id: user_id,
      group_ids: MapSet.new(memberships[:group_ids] || []),
      tenant_ids: MapSet.new(memberships[:tenant_ids] || []),
      provider_codes: MapSet.new(memberships[:provider_codes] || [])
    }

    :ets.insert(@table, {user_id, entry})
    :ok
  end

  @doc """
  Updates a user's cached memberships (merges with existing data).
  """
  @spec update(integer(), map()) :: :ok
  def update(user_id, memberships) do
    case :ets.lookup(@table, user_id) do
      [{^user_id, existing}] ->
        updated = %{
          existing
          | group_ids:
              MapSet.union(existing.group_ids, MapSet.new(memberships[:group_ids] || [])),
            tenant_ids:
              MapSet.union(existing.tenant_ids, MapSet.new(memberships[:tenant_ids] || [])),
            provider_codes:
              MapSet.union(
                existing.provider_codes,
                MapSet.new(memberships[:provider_codes] || [])
              )
        }

        :ets.insert(@table, {user_id, updated})
        :ok

      [] ->
        track(user_id, memberships)
    end
  end

  @doc """
  Removes a user's membership data when they disconnect.
  """
  @spec untrack(integer()) :: :ok
  def untrack(user_id) do
    :ets.delete(@table, user_id)
    :ok
  end

  @doc """
  Returns all tracked user IDs that belong to the given group.
  """
  @spec users_in_group(integer()) :: [integer()]
  def users_in_group(group_id) do
    :ets.foldl(
      fn {user_id, entry}, acc ->
        if MapSet.member?(entry.group_ids, group_id), do: [user_id | acc], else: acc
      end,
      [],
      @table
    )
  end

  @doc """
  Returns all tracked user IDs that belong to the given tenant.
  """
  @spec users_in_tenant(integer()) :: [integer()]
  def users_in_tenant(tenant_id) do
    :ets.foldl(
      fn {user_id, entry}, acc ->
        if MapSet.member?(entry.tenant_ids, tenant_id), do: [user_id | acc], else: acc
      end,
      [],
      @table
    )
  end

  @doc """
  Returns all tracked user IDs that use the given auth provider.
  """
  @spec users_with_provider(String.t()) :: [integer()]
  def users_with_provider(provider_code) do
    :ets.foldl(
      fn {user_id, entry}, acc ->
        if MapSet.member?(entry.provider_codes, provider_code), do: [user_id | acc], else: acc
      end,
      [],
      @table
    )
  end

  @doc """
  Returns the membership data for a specific user, or nil if not tracked.
  """
  @spec get(integer()) :: map() | nil
  def get(user_id) do
    case :ets.lookup(@table, user_id) do
      [{^user_id, entry}] -> entry
      [] -> nil
    end
  end

  @doc """
  Returns all tracked user IDs.
  """
  @spec all_user_ids() :: [integer()]
  def all_user_ids do
    :ets.foldl(fn {user_id, _entry}, acc -> [user_id | acc] end, [], @table)
  end

  # ============================================================================
  # GenServer Callbacks
  # ============================================================================

  @impl true
  def init(_opts) do
    table = :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{table: table}}
  end
end
