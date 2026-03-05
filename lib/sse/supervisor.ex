defmodule KeenAuth.SSE.Supervisor do
  @moduledoc """
  Supervisor for SSE (Server-Sent Events) infrastructure.

  Starts the appropriate presence backend based on configuration:
  - `:local` (default) — starts a `Registry` for single-node presence tracking
  - `:distributed` — starts `Phoenix.Tracker` for cluster-wide presence tracking

  ## Usage

  Add this to your application's supervision tree:

      children = [
        KeenAuth.SSE.Supervisor,
        # ... other children
      ]

  ## Configuration

      config :keen_auth,
        sse: [
          presence: :local,              # :local or :distributed
          pubsub: MyApp.PubSub,          # required for :distributed and SSE delivery
          heartbeat_interval: 30_000,    # SSE ping interval, default 30s
          registry: KeenAuth.SSE.Registry  # Registry name for :local mode
        ]
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    config = Application.get_env(:keen_auth, :sse, [])
    mode = Keyword.get(config, :presence, :local)

    children =
      [KeenAuth.SSE.MembershipCache] ++ presence_children(mode, config)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp presence_children(:local, _config) do
    [
      {Registry, keys: :duplicate, name: registry_name()}
    ]
  end

  defp presence_children(:distributed, config) do
    pubsub = Keyword.fetch!(config, :pubsub)

    [
      # Registry is still needed for local process lookups
      {Registry, keys: :duplicate, name: registry_name()},
      {KeenAuth.SSE.Presence.Distributed, pubsub: pubsub}
    ]
  end

  defp presence_children(_custom_module, _config) do
    # Custom backend — user manages their own supervision
    [
      {Registry, keys: :duplicate, name: registry_name()}
    ]
  end

  @doc """
  Returns the configured registry name (used by the Local backend).
  """
  def registry_name do
    config = Application.get_env(:keen_auth, :sse, [])
    Keyword.get(config, :registry, KeenAuth.SSE.Registry)
  end
end
