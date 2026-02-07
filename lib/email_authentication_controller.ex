defmodule KeenAuth.EmailAuthenticationController do
  @moduledoc """
  Handles email/password authentication as an alternative entry point to OAuth.

  This controller provides the same pipeline integration as OAuth authentication,
  but delegates credential verification to your application via the
  `KeenAuth.EmailAuthenticationHandler` behaviour.

  ## Authentication Flow

  ```
  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
  │ OAuth (Assent)  │     │ Email (You)     │     │                 │
  │ External verify │ OR  │ Local verify    │ ──▶ │ KeenAuth        │
  └────────┬────────┘     └────────┬────────┘     │ Pipeline        │
           │                       │              │                 │
           └───────────┬───────────┘              │ Mapper ──▶      │
                       │                          │ Processor ──▶   │
                       ▼                          │ Storage         │
                 {:ok, raw_user}                  └─────────────────┘
  ```

  Both OAuth and Email authentication produce a `raw_user` map that then flows
  through the standard KeenAuth pipeline (Mapper → Processor → Storage).

  ## Configuration

      config :keen_auth,
        email_enabled: true,
        strategies: [
          email: [
            authentication_handler: MyApp.Auth.EmailHandler,
            mapper: KeenAuth.Mapper.Default,  # or custom
            processor: MyApp.Auth.Processor
          ]
        ]

  ## Implementing the Handler

  You must implement `KeenAuth.EmailAuthenticationHandler` behaviour:

      defmodule MyApp.Auth.EmailHandler do
        @behaviour KeenAuth.EmailAuthenticationHandler

        @impl true
        def authenticate(_conn, %{"email" => email, "password" => password}) do
          case MyApp.Accounts.verify_credentials(email, password) do
            {:ok, user} ->
              # Return raw user map (will be passed to Mapper)
              {:ok, %{
                "sub" => user.id,
                "email" => user.email,
                "name" => user.name
              }}
            :error ->
              {:error, :invalid_credentials}
          end
        end

        @impl true
        def handle_authenticated(conn, _user) do
          # Called after successful auth, before redirect
          conn
        end

        @impl true
        def handle_unauthenticated(conn, _params, _error) do
          conn
          |> Phoenix.Controller.put_flash(:error, "Invalid credentials")
          |> Phoenix.Controller.redirect(to: "/login")
        end
      end

  ## Routes

  When `email_enabled: true`, the following route is added:

      POST /auth/email/new   # Submit email/password form

  ## Security Features

  - Timing attack mitigation via random sleep on failed attempts
  - Redirect URL validation (same as OAuth flow)
  """

  alias KeenAuth.Mapper
  alias KeenAuth.Plug.AuthSession
  alias KeenAuth.Storage
  alias KeenAuth.Processor
  alias KeenAuth.EmailAuthenticationHandler

  use Phoenix.Controller, formats: [:html, :json]

  defmacro __using__(_opts \\ []) do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      @behaviour unquote(__MODULE__)

      def new(conn, params), do: unquote(__MODULE__).new(conn, params)
      # def delete(conn, params), do: unquote(__MODULE__).delete(conn, params)

      defoverridable unquote(__MODULE__)
    end
  end

  # TODO Throttling
  def new(conn, params) do
    provider = :email

    with {:ok, raw_user} <- EmailAuthenticationHandler.authenticate(conn, params),
         response = %{user: raw_user, tokens: nil},
         mapped_user = Mapper.current_mapper(conn, provider).map(provider, raw_user),
         {:ok, conn, user, result} <- Processor.process(conn, provider, mapped_user, response),
         {:ok, conn} <- Storage.store(conn, provider, user, result) do
      EmailAuthenticationHandler.handle_authenticated(conn, user)

      # Regenerate session ID to prevent session fixation
      conn = AuthSession.regenerate(conn)

      conn
      |> redirect_back(params)
    else
      err ->
        Process.sleep(Enum.random(100..300//10))
        # Sleep for random amount to prevent timing attacks

        EmailAuthenticationHandler.handle_unauthenticated(conn, params, err)
    end
  end

  # def delete(conn, params) do
  #   storage = Storage.current_storage(conn)

  #   with user when not is_nil(user) <- storage.current_user(conn) do
  #     conn
  #     |> storage.delete()
  #     |> redirect_back(params)
  #   else
  #     nil ->
  #       redirect_back(conn, params)
  #   end
  # end

  @spec redirect_back(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirect_back(conn, params \\ %{}) do
    KeenAuth.Helpers.RequestHelpers.redirect_back(conn, params)
  end
end
