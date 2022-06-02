defmodule KeenAuth.Storage do
  alias KeenAuth.AuthController

  @callback store(conn :: Plug.Conn.t(), provider :: atom(), oauth_response :: AuthController.oauth_callback_response()) :: {:ok, Plug.Conn.t()}
  @callback current_user(conn :: Plug.Conn.t()) :: any() | nil
  @callback authenticated?(conn :: Plug.Conn.t()) :: boolean()
  @callback get_roles(conn :: Plug.Conn.t()) :: [binary()]
  @callback get_access_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback get_id_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback get_refresh_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback delete(conn :: Plug.Conn.t()) :: Plug.Conn.t()

end
