import Config

# Test configuration
config :test_app, TestAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_at_least_64_bytes_long_for_testing_purposes!!!",
  server: false

# Reduce log noise in tests
config :logger, level: :warning
