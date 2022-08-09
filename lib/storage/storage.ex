defmodule KeenAuth.Storage do
  alias KeenAuth.AuthController
  alias KeenAuth.Config

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

  @storage Config.get_storage()

  def store(conn, provider, oauth_response) do
    @storage.store(conn, provider, oauth_response)
  end

  def current_user(conn) do
    @storage.current_user(conn)
  end

  def authenticated?(conn) do
    @storage.authenticated?(conn)
  end

  def get_access_token(conn) do
    @storage.get_access_token(conn)
  end

  def get_id_token(conn) do
    @storage.get_id_token(conn)
  end

  def get_refresh_token(conn) do
    @storage.get_refresh_token(conn)
  end

  def delete(conn) do
    @storage.delete(conn)
  end

  def put_provider(conn, provider) do
    @storage.put_provider(conn, provider)
  end

  def put_tokens(conn, provider, tokens) do
    @storage.put_tokens(conn, provider, tokens)
  end

  def put_current_user(conn, provider, user) do
    @storage.put_current_user(conn, provider, user)
  end

end
