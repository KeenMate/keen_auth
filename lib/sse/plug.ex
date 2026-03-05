defmodule KeenAuth.SSE.Plug do
  @moduledoc """
  Plug-based Server-Sent Events (SSE) handler for real-time notifications.

  Mounted in the consuming app's router to provide an SSE endpoint
  that pushes events (user disabled, permissions changed, force logout, etc.)
  to connected clients.

  ## Router Integration

      scope "/auth" do
        pipe_through [:browser, :authentication, :require_auth]
        get "/events", KeenAuth.SSE.Plug, []
      end

  ## SSE Event Format

      event: user_disabled
      data: {"user_id":42,"reason":"admin_action","timestamp":"2026-02-20T..."}

      event: permissions_changed
      data: {"user_id":42,"tenant_id":1}

      event: ping
      data: {"server_time":"2026-02-20T..."}

  ## Configuration

      config :keen_auth,
        sse: [
          pubsub: MyApp.PubSub,
          heartbeat_interval: 30_000  # default 30 seconds
        ]
  """

  @behaviour Plug

  require Logger

  alias KeenAuth.SSE.{Presence, Broadcaster}

  @default_heartbeat_interval 30_000

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    config = Application.get_env(:keen_auth, :sse, [])
    pubsub = Keyword.get(config, :pubsub)
    heartbeat_interval = Keyword.get(config, :heartbeat_interval, @default_heartbeat_interval)

    user = KeenAuth.current_user(conn)

    cond do
      is_nil(pubsub) ->
        conn
        |> Plug.Conn.send_resp(503, "SSE not configured: missing pubsub")

      is_nil(user) ->
        conn
        |> Plug.Conn.send_resp(401, "Unauthorized")

      true ->
        user_id = extract_user_id(user)
        start_sse(conn, pubsub, user_id, heartbeat_interval)
    end
  end

  defp start_sse(conn, pubsub, user_id, heartbeat_interval) do
    # Subscribe to user-specific and global PubSub topics
    Phoenix.PubSub.subscribe(pubsub, Broadcaster.user_topic(user_id))
    Phoenix.PubSub.subscribe(pubsub, Broadcaster.global_topic())

    # Register in presence tracking
    Presence.register(user_id)

    Logger.debug("SSE connection opened for user #{user_id}")

    conn =
      conn
      |> Plug.Conn.put_resp_header("content-type", "text/event-stream")
      |> Plug.Conn.put_resp_header("cache-control", "no-cache")
      |> Plug.Conn.put_resp_header("connection", "keep-alive")
      |> Plug.Conn.put_resp_header("access-control-allow-origin", "*")
      |> Plug.Conn.send_chunked(200)

    # Send initial connection event
    send_sse_event(conn, "connected", %{
      user_id: user_id,
      server_time: DateTime.utc_now() |> DateTime.to_iso8601()
    })

    # Start the heartbeat timer
    schedule_heartbeat(heartbeat_interval)

    # Enter the SSE loop
    sse_loop(conn, user_id, heartbeat_interval)
  end

  defp sse_loop(conn, user_id, heartbeat_interval) do
    receive do
      {:sse_event, event, payload} ->
        payload = Map.put(payload, :timestamp, DateTime.utc_now() |> DateTime.to_iso8601())

        case send_sse_event(conn, event, payload) do
          {:ok, conn} ->
            sse_loop(conn, user_id, heartbeat_interval)

          {:error, _reason} ->
            cleanup(user_id)
        end

      :heartbeat ->
        payload = %{server_time: DateTime.utc_now() |> DateTime.to_iso8601()}

        case send_sse_event(conn, "ping", payload) do
          {:ok, conn} ->
            schedule_heartbeat(heartbeat_interval)
            sse_loop(conn, user_id, heartbeat_interval)

          {:error, _reason} ->
            cleanup(user_id)
        end
    end
  end

  defp send_sse_event(conn, event, payload) do
    data = Jason.encode!(payload)
    chunk = "event: #{event}\ndata: #{data}\n\n"

    case Plug.Conn.chunk(conn, chunk) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} -> {:error, reason}
    end
  end

  defp schedule_heartbeat(interval) do
    Process.send_after(self(), :heartbeat, interval)
  end

  defp cleanup(user_id) do
    Presence.unregister(user_id)
    Logger.debug("SSE connection closed for user #{user_id}")
  end

  defp extract_user_id(user) when is_map(user) do
    Map.get(user, :id) || Map.get(user, :user_id) || Map.get(user, "id") || Map.get(user, "user_id")
  end

  defp extract_user_id(%{id: id}), do: id
end
