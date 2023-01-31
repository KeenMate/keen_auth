defmodule KeenAuth.Helpers.RequestHelpers do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  @spec redirect_back(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirect_back(conn, params \\ %{}) do
    redirect_to =
      get_session(conn, :redirect_to) ||
        params["redirect_to"] ||
        "/"

    conn
    |> delete_session(:redirect_to)
    |> redirect(external: redirect_to)
  end
end
