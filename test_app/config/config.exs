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
config :keen_auth,
  email_enabled: true,
  # Enable token storage since we use ETS sessions (no cookie size limit)
  storage_options: [store_tokens: true]

# These are placeholder values - override OAuth providers in config/.local.exs
config :test_app, :keen_auth,
  strategies: [
    # Email authentication - works out of the box for testing
    email: [
      label: "Email",
      icon: "mail",
      color: "#4caf50",
      authentication_handler: TestApp.Auth.EmailHandler,
      mapper: TestApp.Auth.EmailMapper,
      processor: TestApp.Auth.Processor
    ],

    # Azure AD / Entra ID - configure in .local.exs
    entra: [
      label: "Microsoft Entra",
      icon: "microsoft",
      color: "#0078d4",
      strategy: Assent.Strategy.AzureAD,
      mapper: KeenAuth.Mapper.AzureAD,
      processor: TestApp.Auth.Processor,
      config: [
        client_id: "CONFIGURE_IN_LOCAL_EXS",
        client_secret: "CONFIGURE_IN_LOCAL_EXS",
        tenant_id: "CONFIGURE_IN_LOCAL_EXS",
        redirect_uri: "http://localhost:4000/auth/entra/callback"
      ]
    ],

    # GitHub - configure in .local.exs and set enabled: true
    github: [
      enabled: false,
      label: "GitHub",
      icon: "github",
      color: "#333333",
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

# Use Req HTTP adapter for Assent (handles SSL properly)
config :assent, http_adapter: Assent.HTTPAdapter.Req

# Import environment specific config
import_config "#{config_env()}.exs"

# Import local config (gitignored) for secrets
# Copy .local.exs.example to .local.exs and fill in your credentials
File.regular?("config/.local.exs") && import_config(".local.exs")
