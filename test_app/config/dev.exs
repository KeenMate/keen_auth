import Config

# Development configuration
config :test_app, TestAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_at_least_64_bytes_long_for_development_only!!!",
  watchers: [],
  live_reload: [
    patterns: [
      ~r"lib/test_app_web/.*(ex|heex)$",
      # Watch keen_auth library for live reload
      ~r"../lib/.*(ex)$"
    ]
  ],
  # Also recompile keen_auth on changes
  reloadable_compilers: [:gettext, :elixir],
  reloadable_apps: [:test_app, :keen_auth]

# Logging
config :logger, :console, format: "[$level] $message\n"

# Enable dev routes for testing
config :phoenix, :plug_init_mode, :runtime
