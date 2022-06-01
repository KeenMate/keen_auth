defmodule KeenAuth.Storage do
  alias KeenAuth.AuthController

  @callback store(conn :: Plug.Conn.t(), provider :: atom(), oauth_response :: AuthController.oauth_callback_response()) :: {:ok, Plug.Conn.t()}
  @callback current_user(conn :: Plug.Conn.t()) :: KeenAuth.User.t() | nil
  @callback delete(conn :: Plug.Conn.t()) :: Plug.Conn.t()

  @default_store KeenAuth.Storage.Session

  @spec get_store :: KeenAuth.Storage
  def get_store() do
    Application.get_env(:keen_auth, :storage) || @default_store
  end
end
