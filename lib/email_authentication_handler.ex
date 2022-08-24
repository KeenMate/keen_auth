defmodule KeenAuth.EmailAuthenticationHandler do
  alias KeenAuth.Strategy
  alias KeenAuth.Config

  @callback authenticate(conn :: Plug.Conn.t(), params :: map()) :: {:ok, map()} | {:error, :unauthenticated}
  @callback handle_unauthenticated(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  @callback handle_authenticated(conn :: Plug.Conn.t(), user :: KeenAuth.User.t()) :: Plug.Conn.t()

  def authenticate(conn, params) do
    current_authentication_handler!(conn).authenticate(conn, params)
  end

  def handle_unauthenticated(conn, params) do
    current_authentication_handler!(conn).handle_unauthenticated(conn, params)
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
