defmodule KeenAuth.Storage do
  @callback store(conn :: Plug.Conn.t(), provider :: atom(), user :: KeenAuth.User.t(), tokens :: KeenAuth.AuthController.tokens_map()) :: {:ok, Plug.Conn.t()}
  @callback current_user(conn :: Plug.Conn.t()) :: KeenAuth.User.t() | nil

  @default_store KeenAuth.Storage.Session

  @spec get_store :: KeenAuth.Storage
  def get_store() do
    Application.get_env(:keen_auth, :storage) || @default_store
  end
end
