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
end
