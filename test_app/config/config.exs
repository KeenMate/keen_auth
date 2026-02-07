import Config

# Test App configuration
config :test_app, TestAppWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [html: TestAppWeb.ErrorHTML], layout: false],
  pubsub_server: TestApp.PubSub,
  live_view: [signing_salt: "test_salt"]

# JSON library
config :phoenix, :json_library, Jason

# KeenAuth configuration
# These are placeholder values - override them in config/.local.exs
config :test_app, :keen_auth,
  strategies: [
    # Azure AD / Entra ID - configure in .local.exs
    azure_ad: [
      strategy: Assent.Strategy.AzureAD,
      mapper: KeenAuth.Mapper.AzureAD,
      processor: TestApp.Auth.Processor,
      config: [
        client_id: "CONFIGURE_IN_LOCAL_EXS",
        client_secret: "CONFIGURE_IN_LOCAL_EXS",
        tenant_id: "CONFIGURE_IN_LOCAL_EXS",
        redirect_uri: "http://localhost:4000/auth/azure_ad/callback"
      ]
    ],

    # GitHub - configure in .local.exs
    github: [
      strategy: Assent.Strategy.Github,
      mapper: KeenAuth.Mapper.Github,
      processor: TestApp.Auth.Processor,
      config: [
        client_id: "CONFIGURE_IN_LOCAL_EXS",
        client_secret: "CONFIGURE_IN_LOCAL_EXS",
        redirect_uri: "http://localhost:4000/auth/github/callback"
      ]
    ]
  ]

# Import environment specific config
import_config "#{config_env()}.exs"

# Import local config (gitignored) for secrets
# Copy .local.exs.example to .local.exs and fill in your credentials
File.regular?("config/.local.exs") && import_config(".local.exs")
