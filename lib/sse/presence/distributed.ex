defmodule KeenAuth.SSE.Presence.Distributed do
  @moduledoc """
  Phoenix.Tracker-based presence tracking for multi-node clusters.

  Uses a CRDT (Observed-Remove Set) replicated across all nodes via PubSub.
  Automatically cleans up when a tracked process dies (via process linking).

  ## How it works

  - Each SSE connection is tracked under the topic `"sse:user:{user_id}"`
  - Phoenix.Tracker links to the tracked PID — when the SSE process exits,
    the tracker automatically removes the presence entry
  - State is replicated to all cluster nodes via PubSub heartbeats (every 1.5s)
  - `online_users/0` returns users connected across the entire cluster

  ## Configuration

      config :keen_auth,
        sse: [
          presence: :distributed,
          pubsub: MyApp.PubSub
        ]
  """

  @behaviour KeenAuth.SSE.Presence

  use Phoenix.Tracker

  @tracker_name __MODULE__

  def start_link(opts) do
    pubsub = Keyword.fetch!(opts, :pubsub)

    Phoenix.Tracker.start_link(__MODULE__, opts,
      name: @tracker_name,
      pubsub_server: pubsub
    )
  end

  # Phoenix.Tracker callbacks

  @impl Phoenix.Tracker
  def init(opts) do
    server = Keyword.get(opts, :pubsub)
    {:ok, %{pubsub_server: server, node_name: node()}}
  end

  @impl Phoenix.Tracker
  def handle_diff(_diff, state) do
    {:ok, state}
  end

  # KeenAuth.SSE.Presence callbacks

  @impl KeenAuth.SSE.Presence
  def register(user_id, metadata \\ %{}) do
    metadata = Map.put(metadata, :connected_at, DateTime.utc_now())

    # Track on per-user topic AND global topic (for online_users/0)
    with {:ok, _ref} <-
           Phoenix.Tracker.track(@tracker_name, self(), user_topic(user_id), user_id, metadata),
         {:ok, _ref} <-
           Phoenix.Tracker.track(@tracker_name, self(), "sse:online", user_id, metadata) do
      {:ok, self()}
    end
  end

  @impl KeenAuth.SSE.Presence
  def unregister(user_id) do
    Phoenix.Tracker.untrack(@tracker_name, self(), user_topic(user_id), user_id)
    Phoenix.Tracker.untrack(@tracker_name, self(), "sse:online", user_id)
    :ok
  end

  @impl KeenAuth.SSE.Presence
  def list_connections(user_id) do
    topic = user_topic(user_id)

    Phoenix.Tracker.list(@tracker_name, topic)
    |> Enum.map(fn {_key, meta} -> {Map.get(meta, :pid, self()), meta} end)
  end

  @impl KeenAuth.SSE.Presence
  def online?(user_id) do
    topic = user_topic(user_id)
    Phoenix.Tracker.list(@tracker_name, topic) != []
  end

  @impl KeenAuth.SSE.Presence
  def online_users do
    # Phoenix.Tracker doesn't have a "list all topics" API,
    # so we maintain a secondary registration on a global topic
    Phoenix.Tracker.list(@tracker_name, "sse:online")
    |> Enum.map(fn {user_id, _meta} -> user_id end)
    |> Enum.uniq()
  end

  defp user_topic(user_id), do: "sse:user:#{user_id}"
end
