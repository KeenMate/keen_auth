import Config

# Development configuration
config :test_app, TestAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_at_least_64_bytes_long_for_development_only!!!",
  watchers: []

# Logging
config :logger, :console, format: "[$level] $message\n"

# Enable dev routes for testing
config :phoenix, :plug_init_mode, :runtime
