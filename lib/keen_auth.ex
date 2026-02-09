defmodule KeenAuth do
  @moduledoc """
  KeenAuth provides a powerful pipeline-based authentication system for Phoenix applications.

  The library implements a "super simple yet super powerful" approach with two entry points
  (OAuth or Email) that converge into a shared pipeline: Mapper → Processor → Storage.

  ## Architecture Overview

  ```
                      ┌─────────────────────────────────┐
                      │         ENTRY POINTS            │
                      └─────────────────────────────────┘
                                      │
              ┌───────────────────────┴───────────────────────┐
              │                                               │
              ▼                                               ▼
    ┌───────────────────┐                         ┌───────────────────┐
    │   OAuth (Assent)  │                         │   Email (Custom)  │
    │                   │                         │                   │
    │ External provider │                         │ Your app verifies │
    │ verifies creds    │                         │ email/password    │
    └─────────┬─────────┘                         └─────────┬─────────┘
              │                                             │
              │         {:ok, raw_user}                     │
              └───────────────────┬─────────────────────────┘
                                  │
                                  ▼
                      ┌─────────────────────────────────┐
                      │       KEEN AUTH PIPELINE        │
                      └─────────────────────────────────┘
                                  │
                                  ▼
                      ┌─────────────────────────────────┐
                      │  MAPPER                         │
                      │  Normalize raw_user → User      │
                      └─────────────────────────────────┘
                                  │
                                  ▼
                      ┌─────────────────────────────────┐
                      │  PROCESSOR                      │
                      │  Business logic, DB, roles      │
                      └─────────────────────────────────┘
                                  │
                                  ▼
                      ┌─────────────────────────────────┐
                      │  STORAGE                        │
                      │  Persist session/tokens         │
                      └─────────────────────────────────┘
  ```

  ## Entry Points

  - **OAuth** (via Assent): External providers handle credential verification
  - **Email**: Your app implements `KeenAuth.EmailAuthenticationHandler` to verify credentials

  Both entry points produce a `raw_user` map that flows through the same pipeline.

  ## Pipeline Stages

  - **Mapper**: Normalizes user data and can enrich with external API calls
  - **Processor**: Implements business logic, validation, and user transformations
  - **Storage**: Manages data persistence (sessions, database, JWT, custom)

  ## Basic Configuration

  ```elixir
  config :keen_auth,
    strategies: [
      azure_ad: [
        strategy: Assent.Strategy.AzureAD,
        mapper: KeenAuth.Mappers.AzureAD,
        processor: MyApp.Auth.Processor,
        config: [
          tenant_id: System.get_env("AZURE_TENANT_ID"),
          client_id: System.get_env("AZURE_CLIENT_ID"),
          client_secret: System.get_env("AZURE_CLIENT_SECRET"),
          redirect_uri: "https://myapp.com/auth/azure_ad/callback"
        ]
      ],
      github: [
        strategy: Assent.Strategy.Github,
        mapper: KeenAuth.Mappers.Github,
        processor: MyApp.Auth.Processor,
        config: [
          client_id: System.get_env("GITHUB_CLIENT_ID"),
          client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
          redirect_uri: "https://myapp.com/auth/github/callback"
        ]
      ]
    ]
  ```

  ## Router Integration

  Add authentication routes using the macro:

  ```elixir
  defmodule MyAppWeb.Router do
    require KeenAuth

    scope "/auth" do
      pipe_through :browser
      KeenAuth.authentication_routes()
    end
  end
  ```

  ## Usage

  Check authentication status and get current user:

  ```elixir
  if KeenAuth.authenticated?(conn) do
    user = KeenAuth.current_user(conn)
    # User is authenticated
  else
    # Redirect to login
  end
  ```
  """

  alias Plug.Conn

  @type user() :: KeenAuth.User.t() | map() | term()

  @doc """
  Generates authentication routes for the router.

  This macro creates the necessary routes for OAuth authentication flows:
  - `GET /auth/:provider/new` - Initiates OAuth flow
  - `GET /auth/:provider/callback` - Handles OAuth callback
  - `POST /auth/:provider/callback` - Handles OAuth callback (POST)
  - `GET /auth/:provider/delete` - Signs out user
  - `GET /auth/delete` - Signs out user (provider-agnostic)

  Optionally includes email authentication routes if `:email_enabled` is configured.

  ## Example

      defmodule MyAppWeb.Router do
        require KeenAuth

        scope "/auth" do
          pipe_through :browser
          KeenAuth.authentication_routes()
        end
      end

  This will create routes like:
  - `/auth/azure_ad/new`
  - `/auth/github/callback`
  - `/auth/delete`
  """
  defmacro authentication_routes() do
    # TODO since `auth_controller` cannot be retrieved based on OTP app configuration, route to concrete controller in `AuthenticationController` and move default implementation elsewhere
    auth_controller = Application.get_env(:keen_auth, :auth_controller, KeenAuth.AuthenticationController)
    email_enabled = Application.get_env(:keen_auth, :email_enabled, false)

    email_block =
      if email_enabled do
        email_auth_controller = Application.get_env(:keen_auth, :email_auth_controller, KeenAuth.EmailAuthenticationController)

        quote do
          scope "/email" do
            post("/new", unquote(email_auth_controller), :new)
          end
        end
      else
        nil
      end

    quote do
      unquote(email_block)

      scope "/:provider" do
        get("/new", unquote(auth_controller), :new)
        get("/callback", unquote(auth_controller), :callback)
        post("/callback", unquote(auth_controller), :callback)
        get("/delete", unquote(auth_controller), :delete)
      end

      get("/delete", unquote(auth_controller), :delete)
    end
  end

  @doc """
  Returns the current authenticated user from the connection.

  Retrieves the user that was assigned to the connection during the authentication
  process, typically by `KeenAuth.Plug.FetchUser`.

  ## Examples

      iex> KeenAuth.current_user(conn)
      %{id: 123, email: "user@example.com", name: "John Doe"}

      iex> KeenAuth.current_user(unauthenticated_conn)
      nil

  """
  @spec current_user(Conn.t()) :: user()
  def current_user(conn) do
    conn.assigns[:current_user]
  end

  @doc """
  Checks if the current connection has an authenticated user.

  Returns `true` if a user is assigned to the connection, `false` otherwise.

  ## Examples

      iex> KeenAuth.authenticated?(conn_with_user)
      true

      iex> KeenAuth.authenticated?(conn_without_user)
      false

  """
  @spec authenticated?(Conn.t()) :: boolean()
  def authenticated?(conn) do
    current_user(conn) != nil
  end

  @doc """
  Assigns a user to the connection.

  This function is typically used internally by the authentication pipeline,
  but can be useful for testing or manual user assignment.

  ## Examples

      iex> conn = KeenAuth.assign_current_user(conn, user)
      iex> KeenAuth.current_user(conn)
      %{id: 123, email: "user@example.com"}

  """
  @spec assign_current_user(Conn.t(), user()) :: Plug.Conn.t()
  def assign_current_user(conn, user) do
    Conn.assign(conn, :current_user, user)
  end

  @doc """
  Returns a list of configured authentication providers with metadata.

  Useful for dynamically rendering login pages with only the providers
  that are actually configured.

  ## Variants

  - `list_providers(conn)` - Use when you have a connection that went through `KeenAuth.Plug`
  - `list_providers(otp_app)` - Use when you don't have a connection (e.g., login page before auth pipeline)

  ## Options

  Each provider can include optional metadata in its configuration:
  - `:enabled` - Set to `false` to hide provider from list (defaults to `true`)
  - `:label` - Display name (defaults to provider name capitalized)
  - `:icon` - Icon identifier or URL
  - `:color` - Brand color for styling

  ## Example Configuration

      config :my_app, :keen_auth,
        strategies: [
          email: [
            label: "Email",
            icon: "mail",
            authentication_handler: MyApp.Auth.EmailHandler,
            ...
          ],
          entra: [
            label: "Microsoft",
            icon: "microsoft",
            color: "#0078d4",
            strategy: Assent.Strategy.AzureAD,
            ...
          ],
          github: [
            label: "GitHub",
            icon: "github",
            color: "#333",
            strategy: Assent.Strategy.Github,
            ...
          ]
        ]

  ## Example Usage

      # With connection (after going through KeenAuth.Plug pipeline)
      providers = KeenAuth.list_providers(conn)

      # Without connection (e.g., login page)
      providers = KeenAuth.list_providers(:my_app)

      # Returns:
      [
        %{name: :email, label: "Email", icon: "mail", path: "/auth/email/new", color: nil},
        %{name: :entra, label: "Microsoft", icon: "microsoft", path: "/auth/entra/new", color: "#0078d4"},
        %{name: :github, label: "GitHub", icon: "github", path: "/auth/github/new", color: "#333"}
      ]

      # In your template
      <%= for provider <- @providers do %>
        <a href={provider.path} style={"background: \#{provider.color}"}>
          <i class={"icon-\#{provider.icon}"}></i>
          <%= provider.label %>
        </a>
      <% end %>

  """
  @spec list_providers(Conn.t() | atom()) :: [map()]
  def list_providers(%Conn{} = conn) do
    config = KeenAuth.Plug.fetch_config(conn)
    strategies = KeenAuth.Config.get(config, :strategies, [])
    build_provider_list(strategies)
  end

  def list_providers(otp_app) when is_atom(otp_app) do
    strategies = Application.get_env(otp_app, :keen_auth, []) |> Keyword.get(:strategies, [])
    build_provider_list(strategies)
  end

  defp build_provider_list(strategies) do
    strategies
    |> Enum.filter(fn {_name, opts} -> Keyword.get(opts, :enabled, true) end)
    |> Enum.map(fn {name, opts} ->
      %{
        name: name,
        label: Keyword.get(opts, :label, default_label(name)),
        icon: Keyword.get(opts, :icon),
        color: Keyword.get(opts, :color),
        path: provider_path(name)
      }
    end)
  end

  @doc """
  Returns a list of configured provider names (atoms).

  Simpler alternative to `list_providers/1` when you only need the names.

  ## Example

      KeenAuth.provider_names(conn)
      #=> [:email, :entra, :github]

  """
  @spec provider_names(Conn.t()) :: [atom()]
  def provider_names(conn) do
    config = KeenAuth.Plug.fetch_config(conn)
    strategies = KeenAuth.Config.get(config, :strategies, [])
    Keyword.keys(strategies)
  end

  @doc """
  Renders provider buttons using a custom callback function.

  This function takes a list of providers (from `list_providers/1`) and a render
  callback that returns HTML for each provider. This allows the same provider list
  to be rendered differently in different contexts.

  ## Parameters

  - `providers` - List of provider maps from `list_providers/1`
  - `render_fn` - Function that takes a provider map and returns an HTML string

  ## Provider Map Fields

  The callback receives a map with these fields:
  - `:name` - Provider atom (e.g., `:github`, `:entra`)
  - `:label` - Display name (e.g., "GitHub", "Microsoft Entra")
  - `:icon` - Icon identifier (if configured)
  - `:color` - Brand color (if configured)
  - `:path` - Authentication path (e.g., "/auth/github/new")

  ## Examples

      providers = KeenAuth.list_providers(:my_app)

      # Small inline buttons for navbar
      KeenAuth.render_providers(providers, fn p ->
        ~s(<a href="\#{p.path}" class="btn btn-sm">\#{p.label}</a>)
      end)

      # Large buttons with icons for login page
      KeenAuth.render_providers(providers, fn p ->
        ~s'''
        <a href="\#{p.path}" class="login-btn" style="background: \#{p.color || "#333"}">
          <i class="icon-\#{p.icon}"></i>
          <span>\#{p.label}</span>
        </a>
        '''
      end)

      # Filter OAuth providers only (exclude email)
      providers
      |> Enum.reject(& &1.name == :email)
      |> KeenAuth.render_providers(fn p ->
        ~s(<button onclick="location.href='\#{p.path}'">\#{p.label}</button>)
      end)

  """
  @spec render_providers([map()], (map() -> String.t())) :: String.t()
  def render_providers(providers, render_fn) when is_list(providers) and is_function(render_fn, 1) do
    Enum.map_join(providers, "", render_fn)
  end

  defp default_label(name) do
    name
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp provider_path(:email), do: "/auth/email/new"
  defp provider_path(name), do: "/auth/#{name}/new"
end
