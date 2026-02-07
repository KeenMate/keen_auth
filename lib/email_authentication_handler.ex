defmodule KeenAuth.EmailAuthenticationHandler do
  @moduledoc """
  Behaviour for implementing email/password authentication.

  This is the entry point for email-based authentication, equivalent to what
  OAuth providers (via Assent) do for OAuth flows. Your implementation verifies
  credentials and returns a raw user map that flows through the KeenAuth pipeline.

  ## Pipeline Position

  ```
  ┌──────────────────────┐
  │ EmailAuthHandler     │  ◀── YOU IMPLEMENT THIS
  │ (credential verify)  │
  └──────────┬───────────┘
             │ {:ok, raw_user}
             ▼
  ┌──────────────────────┐
  │ Mapper               │  Normalize to KeenAuth.User
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ Processor            │  Business logic, DB ops
  └──────────┬───────────┘
             ▼
  ┌──────────────────────┐
  │ Storage              │  Persist session
  └──────────────────────┘
  ```

  ## Callbacks

  - `authenticate/2` - Verify credentials, return `{:ok, user_map}` or `{:error, reason}`
  - `handle_authenticated/2` - Called after successful auth (logging, side effects)
  - `handle_unauthenticated/3` - Handle failed auth (render error, redirect)

  ## Example Implementation

      defmodule MyApp.Auth.EmailHandler do
        @behaviour KeenAuth.EmailAuthenticationHandler
        import Plug.Conn
        import Phoenix.Controller

        @impl true
        def authenticate(_conn, %{"email" => email, "password" => password}) do
          with {:ok, user} <- MyApp.Accounts.get_user_by_email(email),
               :ok <- MyApp.Accounts.verify_password(user, password) do
            # Return raw user map - will be passed to Mapper
            {:ok, %{
              "sub" => to_string(user.id),
              "email" => user.email,
              "name" => user.display_name,
              "preferred_username" => user.username
            }}
          else
            _ -> {:error, :invalid_credentials}
          end
        end

        @impl true
        def handle_authenticated(conn, user) do
          # Optional: audit log, analytics, etc.
          Logger.info("User \#{user.email} signed in via email")
          conn
        end

        @impl true
        def handle_unauthenticated(conn, params, {:error, :invalid_credentials}) do
          conn
          |> put_flash(:error, "Invalid email or password")
          |> redirect(to: params["redirect_to"] || "/login")
        end

        def handle_unauthenticated(conn, _params, _other_error) do
          conn
          |> put_flash(:error, "Authentication failed")
          |> redirect(to: "/login")
        end
      end

  ## Configuration

      config :keen_auth,
        email_enabled: true,
        strategies: [
          email: [
            authentication_handler: MyApp.Auth.EmailHandler,
            mapper: KeenAuth.Mapper.Default,
            processor: MyApp.Auth.Processor
          ]
        ]
  """

  alias KeenAuth.Strategy
  alias KeenAuth.Config

  @doc """
  Verify user credentials and return raw user data.

  Called when a user submits the login form. Should validate the email/password
  and return a map with user data that will be passed to the Mapper.

  ## Return Values

  - `{:ok, user_map}` - Credentials valid. `user_map` should include keys like
    `"sub"`, `"email"`, `"name"` that your Mapper expects.
  - `{:error, reason}` - Credentials invalid. `reason` is passed to
    `handle_unauthenticated/3`.
  """
  @callback authenticate(conn :: Plug.Conn.t(), params :: map()) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Handle failed authentication attempts.

  Called when `authenticate/2` returns an error. Should render an error message
  or redirect the user back to the login page.

  The controller adds a random delay before calling this to prevent timing attacks.
  """
  @callback handle_unauthenticated(
              conn :: Plug.Conn.t(),
              params :: map(),
              error :: term()
            ) :: Plug.Conn.t()

  @doc """
  Called after successful authentication, before redirect.

  Use for side effects like audit logging. The return value should be the conn
  (potentially modified).
  """
  @callback handle_authenticated(conn :: Plug.Conn.t(), user :: KeenAuth.User.t()) ::
              Plug.Conn.t()

  def authenticate(conn, params) do
    current_authentication_handler!(conn).authenticate(conn, params)
  end

  def handle_unauthenticated(conn, params, err) do
    current_authentication_handler!(conn).handle_unauthenticated(conn, params, err)
  end

  def handle_authenticated(conn, user) do
    current_authentication_handler!(conn).handle_authenticated(conn, user)
  end

  def current_authentication_handler!(conn) do
    conn
    |> KeenAuth.Plug.fetch_config()
    |> get_authentication_handler!()
  end

  def get_authentication_handler!(config) do
    Strategy.get_strategy!(config, :email)[:authentication_handler] || Config.raise_error("Authentication handler not defined")
  end
end
