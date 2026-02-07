import Config

# Production configuration - customize as needed
config :test_app, TestAppWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

# Runtime configuration
config :test_app, TestAppWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")
