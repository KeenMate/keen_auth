defmodule KeenAuth.Storage.Session do
  @moduledoc """
  Session-based storage for KeenAuth authentication data.

  This storage implementation uses Phoenix sessions (cookies) to persist
  authentication state. It stores the current user and provider information.

  ## Cookie Size Limitation

  **Important**: Cookie sessions have a 4KB size limit. OAuth tokens (especially
  from providers like Azure AD/Entra) can easily exceed this limit.

  By default, this storage does NOT store OAuth tokens to avoid cookie overflow.
  If you need to store tokens, either:

  1. **Use server-side storage** - Implement custom storage using ETS, database,
     or Redis to store tokens server-side
  2. **Enable token storage** - Set `store_tokens: true` in config (only if you're
     sure your tokens fit within the cookie limit)

  ## Configuration

      config :keen_auth,
        storage: KeenAuth.Storage.Session,
        storage_options: [
          store_tokens: false  # default, don't store tokens in cookie
        ]

  ## Custom Storage Example

  For applications that need token storage:

      defmodule MyApp.Auth.Storage do
        @behaviour KeenAuth.Storage

        def store(conn, provider, user, oauth_response) do
          # Store tokens in database/ETS
          {:ok, session} = MyApp.Sessions.create(user, oauth_response[:token])

          # Only store session ID in cookie
          conn = put_session(conn, :session_id, session.id)
          {:ok, conn}
        end

        def get_access_token(conn) do
          with session_id when not is_nil(session_id) <- get_session(conn, :session_id),
               session <- MyApp.Sessions.get(session_id) do
            session.access_token
          end
        end

        # ... implement other callbacks
      end
  """

  @behaviour KeenAuth.Storage

  import Plug.Conn, only: [put_session: 3, get_session: 2, delete_session: 2]

  @impl true
  def store(conn, provider, mapped_user, oauth_response) do
    store_tokens? = get_storage_option(conn, :store_tokens, false)

    conn =
      conn
      |> put_provider(provider)
      |> maybe_put_tokens(provider, oauth_response[:token], store_tokens?)
      |> put_current_user(provider, mapped_user)

    {:ok, conn}
  end

  defp maybe_put_tokens(conn, _provider, _tokens, false), do: conn
  defp maybe_put_tokens(conn, provider, tokens, true), do: put_tokens(conn, provider, tokens)

  defp get_storage_option(conn, key, default) do
    config = KeenAuth.Plug.fetch_config(conn)
    options = KeenAuth.Config.get(config, :storage_options, [])
    Keyword.get(options, key, default)
  end

  @impl true
  def current_user(conn) do
    get_session(conn, :current_user)
  end

  @impl true
  def authenticated?(conn) do
    current_user(conn) != nil
  end

  @impl true
  def get_access_token(conn) do
    get_session(conn, :access_token)
  end

  @impl true
  def get_id_token(conn) do
    get_session(conn, :id_token)
  end

  @impl true
  def get_refresh_token(conn) do
    get_session(conn, :refresh_token)
  end

  @impl true
  def delete(conn) do
    conn
    |> put_current_user()
    |> put_access_token()
  end

  @impl true
  def get_provider(conn) do
    get_session(conn, :provider)
  end

  @impl true
  def put_provider(conn, provider \\ nil)

  def put_provider(conn, nil) do
    delete_session(conn, :provider)
  end

  def put_provider(conn, provider) do
    put_session(conn, :provider, provider)
  end

  @impl true
  def put_current_user(conn, provider \\ nil, user \\ nil)

  def put_current_user(conn, _provider, nil) do
    delete_session(conn, :current_user)
  end

  def put_current_user(conn, _provider, user) do
    put_session(conn, :current_user, user)
  end

  @impl true
  def put_tokens(conn, provider, tokens) do
    conn
    |> put_access_token(provider, tokens["access_token"])
    |> put_id_token(provider, tokens["id_token"])
    |> put_refresh_token(provider, tokens["refresh_token"])
  end

  def put_access_token(conn, provider \\ nil, token \\ nil)

  def put_access_token(conn, _provider, nil) do
    conn
    |> delete_session(:access_claims)
    |> delete_session(:access_token)
  end

  def put_access_token(conn, _provider, token) do
    put_session(conn, :access_token, token)
  end

  def put_id_token(conn, provider \\ nil, token \\ nil)

  def put_id_token(conn, _provider, nil) do
    delete_session(conn, :id_token)
  end

  def put_id_token(conn, _provider, token) do
    put_session(conn, :id_token, token)
  end

  @spec put_refresh_token(Plug.Conn.t(), any, any) :: Plug.Conn.t()
  def put_refresh_token(conn, provider \\ nil, token \\ nil)

  def put_refresh_token(conn, _provider, nil) do
    delete_session(conn, :refresh_token)
  end

  def put_refresh_token(conn, _provider, token) do
    put_session(conn, :refresh_token, token)
  end
end
