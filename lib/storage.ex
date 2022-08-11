defmodule KeenAuth.Storage do
  alias KeenAuth.AuthController
  alias KeenAuth.Config

  @default_storage KeenAuth.Storage.Session

  @callback store(conn :: Plug.Conn.t(), provider :: atom(), oauth_response :: AuthController.oauth_callback_response()) :: {:ok, Plug.Conn.t()}
  @callback current_user(conn :: Plug.Conn.t()) :: any() | nil
  @callback authenticated?(conn :: Plug.Conn.t()) :: boolean()
  @callback get_access_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback get_id_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback get_refresh_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback delete(conn :: Plug.Conn.t()) :: Plug.Conn.t()
  @callback put_provider(conn :: Plug.Conn.t(), provider :: atom()) :: Plug.Conn.t()
  @callback put_tokens(conn :: Plug.Conn.t(), provider :: atom(), AuthController.tokens_map()) :: Plug.Conn.t()
  @callback put_current_user(conn :: Plug.Conn.t(), provider :: atom(), KeenAuth.User.t() | map()) :: Plug.Conn.t()

  def store(conn, provider, oauth_response) do
    current_storage(conn).store(conn, provider, oauth_response)
  end

  def current_user(conn) do
    current_storage(conn).current_user(conn)
  end

  def authenticated?(conn) do
    current_storage(conn).authenticated?(conn)
  end

  def get_access_token(conn) do
    current_storage(conn).get_access_token(conn)
  end

  def get_id_token(conn) do
    current_storage(conn).get_id_token(conn)
  end

  def get_refresh_token(conn) do
    current_storage(conn).get_refresh_token(conn)
  end

  def delete(conn) do
    current_storage(conn).delete(conn)
  end

  def put_provider(conn, provider) do
    current_storage(conn).put_provider(conn, provider)
  end

  def put_tokens(conn, provider, tokens) do
    current_storage(conn).put_tokens(conn, provider, tokens)
  end

  def put_current_user(conn, provider, user) do
    current_storage(conn).put_current_user(conn, provider, user)
  end

  def current_storage(conn) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_storage()
  end

  def get_storage(config) do
    Config.get(config, :storage, @default_storage)
  end
end
