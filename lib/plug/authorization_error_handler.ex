defmodule KeenAuth.Plug.AuthorizationErrorHandler do
  alias Plug.Conn

  import Conn

  @callback call(Conn.t(), :unauthorized | :forbidden) :: Conn.t()

  def call(conn, :unauthorized) do
    conn
    |> send_resp(401, "Unauthorized")
  end
end
