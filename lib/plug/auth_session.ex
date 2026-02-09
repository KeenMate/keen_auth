defmodule KeenAuth.Plug.AuthSession do
  @moduledoc """
  A separate session cookie for OAuth authentication flow.

  This plug creates a dedicated short-lived session cookie for storing OAuth state
  (nonce, PKCE verifier, redirect URL) during the authentication flow. This provides
  several security benefits:

  ## Why Dual Cookies?

  OAuth providers like Microsoft Entra can use `form_post` response mode (POST callback)
  which is more secure than `query` mode (tokens don't appear in URL/browser history).
  However, `SameSite=Lax` cookies are NOT sent on cross-site POST requests.

  The solution is two cookies:
  - **Auth cookie**: `SameSite=None; Secure` - sent on cross-site POSTs, short-lived (5 min)
  - **Main cookie**: `SameSite=Lax` or `Strict` - not sent cross-site, long-lived

  ## Security Benefits

  - **Session fixation prevention**: New session ID after authentication
  - **Minimal exposure window**: Auth cookie expires in 5 minutes
  - **Token security**: Allows `form_post` mode (tokens not in URL)
  - **Cookie isolation**: Auth state separate from user session

  ## Usage

  Add to your router's authentication pipeline:

      pipeline :authentication do
        plug KeenAuth.Plug, otp_app: :my_app
        plug KeenAuth.Plug.AuthSession
      end

  ## Configuration

  Configure in your endpoint or via plug options:

      plug KeenAuth.Plug.AuthSession,
        key: "_my_app_auth",
        signing_salt: "auth_signing_salt",
        encryption_salt: "auth_encryption_salt",
        same_site: "None",  # Required for cross-site POST
        secure: true,       # Required with SameSite=None
        max_age: 300        # 5 minutes

  ## How It Works

  1. OAuth `/new` → State stored in auth cookie (`SameSite=None`)
  2. Provider redirects with POST → Auth cookie sent (cross-site OK)
  3. OAuth `/callback` → State validated and cleared
  4. Success → User stored in main session, auth cookie deleted
  """

  @behaviour Plug

  import Plug.Conn

  @default_options [
    key: "_keen_auth",
    signing_salt: "keen_auth_signing",
    encryption_salt: "keen_auth_encrypt",
    same_site: "None",
    secure: true,
    http_only: true,
    max_age: 300
  ]

  @impl true
  def init(opts) do
    Keyword.merge(@default_options, opts)
  end

  @impl true
  def call(conn, opts) do
    conn
    |> fetch_cookies()
    |> fetch_auth_cookie(opts)
    |> put_private(:keen_auth_session_opts, opts)
    |> register_before_send(&persist_auth_cookie/1)
  end

  defp fetch_auth_cookie(conn, opts) do
    key = Keyword.fetch!(opts, :key)
    signing_salt = Keyword.fetch!(opts, :signing_salt)
    encryption_salt = Keyword.fetch!(opts, :encryption_salt)
    secret = get_secret(conn)

    data =
      case conn.cookies[key] do
        nil ->
          %{}

        cookie_value ->
          case decrypt_cookie(cookie_value, secret, signing_salt, encryption_salt) do
            {:ok, data} -> data
            :error -> %{}
          end
      end

    put_private(conn, :keen_auth_session, data)
  end

  defp persist_auth_cookie(conn) do
    case conn.private[:keen_auth_session_changed] do
      true ->
        write_auth_cookie(conn)

      _ ->
        conn
    end
  end

  defp write_auth_cookie(conn) do
    opts = conn.private[:keen_auth_session_opts]
    data = conn.private[:keen_auth_session] || %{}
    key = Keyword.fetch!(opts, :key)
    signing_salt = Keyword.fetch!(opts, :signing_salt)
    encryption_salt = Keyword.fetch!(opts, :encryption_salt)
    secret = get_secret(conn)

    cookie_opts = [
      http_only: Keyword.get(opts, :http_only, true),
      secure: Keyword.get(opts, :secure, true),
      same_site: Keyword.get(opts, :same_site, "None"),
      max_age: Keyword.get(opts, :max_age, 300),
      path: "/"
    ]

    if map_size(data) == 0 do
      delete_resp_cookie(conn, key, cookie_opts)
    else
      encrypted = encrypt_cookie(data, secret, signing_salt, encryption_salt)
      put_resp_cookie(conn, key, encrypted, cookie_opts)
    end
  end

  defp get_secret(conn) do
    conn.secret_key_base ||
      raise "secret_key_base not set on conn - ensure Plug.Session is configured"
  end

  defp encrypt_cookie(data, secret, signing_salt, encryption_salt) do
    secret_key = Plug.Crypto.KeyGenerator.generate(secret, encryption_salt, iterations: 1000, length: 32)
    sign_key = Plug.Crypto.KeyGenerator.generate(secret, signing_salt, iterations: 1000, length: 32)

    data
    |> :erlang.term_to_binary()
    |> Plug.Crypto.MessageEncryptor.encrypt(secret_key, sign_key)
  end

  defp decrypt_cookie(cookie, secret, signing_salt, encryption_salt) do
    secret_key = Plug.Crypto.KeyGenerator.generate(secret, encryption_salt, iterations: 1000, length: 32)
    sign_key = Plug.Crypto.KeyGenerator.generate(secret, signing_salt, iterations: 1000, length: 32)

    case Plug.Crypto.MessageEncryptor.decrypt(cookie, secret_key, sign_key) do
      {:ok, binary} ->
        {:ok, Plug.Crypto.non_executable_binary_to_term(binary)}

      :error ->
        :error
    end
  end

  # ============================================================================
  # Public API - called by KeenAuth controllers
  # ============================================================================

  @doc """
  Get a value from the auth session.
  """
  @spec get(Plug.Conn.t(), atom()) :: any()
  def get(conn, key) do
    data = conn.private[:keen_auth_session] || %{}
    Map.get(data, key)
  end

  @doc """
  Put a value in the auth session.
  """
  @spec put(Plug.Conn.t(), atom(), any()) :: Plug.Conn.t()
  def put(conn, key, value) do
    data = conn.private[:keen_auth_session] || %{}
    new_data = Map.put(data, key, value)

    conn
    |> put_private(:keen_auth_session, new_data)
    |> put_private(:keen_auth_session_changed, true)
  end

  @doc """
  Delete a value from the auth session.
  """
  @spec delete(Plug.Conn.t(), atom()) :: Plug.Conn.t()
  def delete(conn, key) do
    data = conn.private[:keen_auth_session] || %{}
    new_data = Map.delete(data, key)

    conn
    |> put_private(:keen_auth_session, new_data)
    |> put_private(:keen_auth_session_changed, true)
  end

  @doc """
  Get a value from auth session and delete it atomically.
  """
  @spec get_and_delete(Plug.Conn.t(), atom()) :: {Plug.Conn.t(), any()}
  def get_and_delete(conn, key) do
    value = get(conn, key)
    conn = delete(conn, key)
    {conn, value}
  end

  @doc """
  Clear the entire auth session.
  """
  @spec clear(Plug.Conn.t()) :: Plug.Conn.t()
  def clear(conn) do
    conn
    |> put_private(:keen_auth_session, %{})
    |> put_private(:keen_auth_session_changed, true)
  end

  @doc """
  Clear auth session and regenerate the main session ID.

  Call this after successful authentication to:
  1. Clear OAuth flow data from auth cookie
  2. Regenerate main session ID (prevents session fixation)
  """
  @spec clear_and_regenerate(Plug.Conn.t()) :: Plug.Conn.t()
  def clear_and_regenerate(conn) do
    conn
    |> clear()
    |> configure_session(renew: true)
  end

  @doc """
  Regenerate main session ID without clearing auth data.
  """
  @spec regenerate(Plug.Conn.t()) :: Plug.Conn.t()
  def regenerate(conn) do
    configure_session(conn, renew: true)
  end
end
