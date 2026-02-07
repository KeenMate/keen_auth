defmodule TestAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :test_app

  @session_options [
    store: :cookie,
    key: "_test_app_key",
    signing_salt: "test_salt_change_in_prod",
    same_site: "Lax"
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
