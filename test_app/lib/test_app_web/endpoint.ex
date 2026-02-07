defmodule TestAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :test_app

  # ETS-based session configuration (server-side, no cookie size limit)
  # This allows storing OAuth tokens without hitting the 4KB cookie limit.
  #
  # For production, consider using a persistent store like Redis or Database.
  @session_options [
    store: :ets,
    key: "_test_app_session",
    signing_salt: "test_salt_change_in_prod",
    table: :test_app_sessions,
    same_site: "Lax",
    http_only: true
    # secure: true  # Enable in production with HTTPS
  ]

  plug Plug.Static,
    at: "/",
    from: :test_app,
    gzip: false,
    only: TestAppWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug TestAppWeb.Router
end
