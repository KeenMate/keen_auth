defmodule KeenAuth.Storage.Session do
  @behaviour KeenAuth.Storage

  import Plug.Conn, only: [put_session: 3, get_session: 2]

  @impl true
  def store(conn, _provider, user, %{"access_token" => access_token}) do
    conn =
      conn
      |> put_session(:current_user, user)
      |> put_session(:access_token, access_token)

    {:ok, conn}
  end

  @impl true
  def current_user(conn) do
    get_session(conn, :current_user)
  end
end
