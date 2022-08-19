defmodule KeenAuth.EmailAuthenticationHandler do
  alias KeenAuth.Config

  @callback authenticate(conn :: Plug.Conn.t(), username :: binary(), password :: binary()) :: {:ok, map()} | {:error, :unauthenticated}
  @callback handle_unauthorized(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  @callback handle_authenticated(conn :: Plug.Conn.t(), user :: KeenAuth.User.t()) :: Plug.Conn.t()

  def authenticate(conn, username, password) do
    current_authentication_handler!(conn).authenticate(conn, username, password)
  end

  def handle_unauthorized(conn, params) do
    current_authentication_handler!(conn).handle_unauthorized(conn, params)
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
    Config.get(config, :authentication_handler) || Config.raise_error("Authentication handler not defined")
  end
end
