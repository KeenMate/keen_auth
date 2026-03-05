defmodule KeenAuth.SSE.Broadcaster do
  @moduledoc """
  Convenience module for broadcasting events to SSE-connected users via PubSub.

  ## PubSub Topics

  - `"keen_auth:user:{user_id}"` — per-user events
  - `"keen_auth:global"` — broadcast to all connected users

  ## Examples

      # Send event to a specific user
      KeenAuth.SSE.Broadcaster.broadcast(MyApp.PubSub, 42, "user_disabled", %{reason: "admin_action"})

      # Send to multiple users
      KeenAuth.SSE.Broadcaster.broadcast_many(MyApp.PubSub, [42, 43], "permissions_changed", %{})

      # Broadcast to everyone
      KeenAuth.SSE.Broadcaster.broadcast_all(MyApp.PubSub, "maintenance", %{message: "Server restart in 5m"})
  """

  @doc """
  Returns the PubSub topic for a specific user.
  """
  @spec user_topic(integer()) :: String.t()
  def user_topic(user_id), do: "keen_auth:user:#{user_id}"

  @doc """
  Returns the global PubSub topic for all connected users.
  """
  @spec global_topic() :: String.t()
  def global_topic, do: "keen_auth:global"

  @doc """
  Broadcasts an event to a specific user via PubSub.
  """
  @spec broadcast(module(), integer(), String.t(), map()) :: :ok | {:error, term()}
  def broadcast(pubsub, user_id, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast(pubsub, user_topic(user_id), {:sse_event, event, payload})
  end

  @doc """
  Broadcasts an event to multiple users via PubSub.
  """
  @spec broadcast_many(module(), [integer()], String.t(), map()) :: :ok
  def broadcast_many(pubsub, user_ids, event, payload \\ %{}) do
    Enum.each(user_ids, fn user_id ->
      broadcast(pubsub, user_id, event, payload)
    end)
  end

  @doc """
  Broadcasts an event to all connected users via the global topic.
  """
  @spec broadcast_all(module(), String.t(), map()) :: :ok | {:error, term()}
  def broadcast_all(pubsub, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast(pubsub, global_topic(), {:sse_event, event, payload})
  end
end
