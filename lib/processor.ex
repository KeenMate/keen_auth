defmodule KeenAuth.Processor do
  @callback process(conn :: Plug.Conn.t(), provider :: atom(), response :: KeenAuth.AuthController.oauth_callback_response()) :: {:ok, Plug.Conn.t(), KeenAuth.User.t()} | Plug.Conn.t()

  def process(conn, _provider, %{user: user}) do
    {:ok, conn, user}
  end
end
