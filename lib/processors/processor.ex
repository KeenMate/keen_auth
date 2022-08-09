defmodule KeenAuth.Processor do
  alias KeenAuth.AuthController

  @callback process(conn :: Plug.Conn.t(), provider :: atom(), response :: AuthController.oauth_callback_response())
    :: {:ok, Plug.Conn.t(), AuthController.oauth_callback_result()} | Plug.Conn.t()

  def process(conn, _provider, oauth_response) do
    {:ok, conn, oauth_response}
  end
end
