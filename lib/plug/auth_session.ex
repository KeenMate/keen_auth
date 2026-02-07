defmodule KeenAuth.Plug.AuthSession do
  @moduledoc """
  Provides a namespaced temporary storage within the session for OAuth flow.

  This module separates OAuth state (nonce, PKCE verifier, redirect URL) from
  the main user session data. After successful authentication, the auth data
  is cleared and the session can be regenerated for security.

  ## Why Separate Auth State?

  - **Clean Separation**: OAuth flow data doesn't pollute user session
  - **Session Regeneration**: Easy to clear auth state and regenerate session ID
  - **Security**: Prevents session fixation by regenerating after auth

  ## Usage

  The auth session is automatically used by KeenAuth controllers. For custom
  implementations, you can use the helper functions:

      # Store OAuth state before redirect
      conn = KeenAuth.Plug.AuthSession.put(conn, :session_params, session_params)

      # Retrieve on callback
      {conn, session_params} = KeenAuth.Plug.AuthSession.get_and_delete(conn, :session_params)

      # Clear all auth data and regenerate session after successful auth
      conn = KeenAuth.Plug.AuthSession.clear_and_regenerate(conn)

  ## Session Regeneration

  After successful authentication, call `clear_and_regenerate/1` to:
  1. Clear all OAuth flow data from the session
  2. Configure the session for renewal (new session ID)

  This prevents session fixation attacks where an attacker could set a known
  session ID before authentication.
  """

  import Plug.Conn

  @session_namespace :keen_auth

  @doc """
  Get a value from the auth session namespace.
  """
  @spec get(Plug.Conn.t(), atom()) :: any()
  def get(conn, key) do
    auth_data = get_session(conn, @session_namespace) || %{}
    Map.get(auth_data, key)
  end

  @doc """
  Put a value in the auth session namespace.
  """
  @spec put(Plug.Conn.t(), atom(), any()) :: Plug.Conn.t()
  def put(conn, key, value) do
    auth_data = get_session(conn, @session_namespace) || %{}
    new_data = Map.put(auth_data, key, value)
    put_session(conn, @session_namespace, new_data)
  end

  @doc """
  Delete a value from the auth session namespace.
  """
  @spec delete(Plug.Conn.t(), atom()) :: Plug.Conn.t()
  def delete(conn, key) do
    auth_data = get_session(conn, @session_namespace) || %{}
    new_data = Map.delete(auth_data, key)
    put_session(conn, @session_namespace, new_data)
  end

  @doc """
  Get a value from auth session and delete it atomically.
  Useful for one-time values like OAuth state.
  """
  @spec get_and_delete(Plug.Conn.t(), atom()) :: {Plug.Conn.t(), any()}
  def get_and_delete(conn, key) do
    value = get(conn, key)
    conn = delete(conn, key)
    {conn, value}
  end

  @doc """
  Clear all auth session data.
  """
  @spec clear(Plug.Conn.t()) :: Plug.Conn.t()
  def clear(conn) do
    delete_session(conn, @session_namespace)
  end

  @doc """
  Clear auth session data and regenerate the session ID.

  This should be called after successful authentication to prevent
  session fixation attacks. It:
  1. Clears all OAuth flow data
  2. Configures the session to be renewed (new session ID)

  The actual session data (like current_user) is preserved, only the
  session ID changes.

  ## Example

      def process(conn, provider, user, oauth_result) do
        # After successful authentication
        conn = KeenAuth.Plug.AuthSession.clear_and_regenerate(conn)
        {:ok, conn, user, oauth_result}
      end
  """
  @spec clear_and_regenerate(Plug.Conn.t()) :: Plug.Conn.t()
  def clear_and_regenerate(conn) do
    conn
    |> clear()
    |> configure_session(renew: true)
  end

  @doc """
  Regenerate session ID without clearing auth data.

  Use this if you want to keep auth data but still regenerate the session ID.
  """
  @spec regenerate(Plug.Conn.t()) :: Plug.Conn.t()
  def regenerate(conn) do
    configure_session(conn, renew: true)
  end
end
