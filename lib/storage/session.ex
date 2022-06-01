defmodule KeenAuth.Storage.Session do
  @behaviour KeenAuth.Storage

  import Plug.Conn, only: [put_session: 3, get_session: 2, delete_session: 2]

  @impl true
  def store(conn, provider, %{user: user, token: tokens}) do
    conn =
      conn
      |> put_provider(provider)
      |> put_access_token(tokens["access_token"])
      |> put_current_user(user)

    {:ok, conn}
  end

  @impl true
  def current_user(conn) do
    get_session(conn, :current_user)
  end

  @impl true
  def delete(conn) do
    conn
    |> put_current_user()
    |> put_access_token()
  end

  def get_provider(conn) do
    get_session(conn, :provider)
  end

  def put_provider(conn, provider \\ nil)

  def put_provider(conn, provider) do
    put_session(conn, :provider, provider)
  end

  def put_provider(conn, provider) do
    put_session(conn, :provider, provider)
  end

  def put_current_user(conn, user \\ nil)

  def put_current_user(conn, nil) do
    delete_session(conn, :current_user)
  end

  def put_current_user(conn, user) do
    put_session(conn, :current_user, user)
  end

  def put_access_token(conn, access_token \\ nil)

  def put_access_token(conn, nil) do
    delete_session(conn, :access_token)
  end

  def put_access_token(conn, access_token) do
    put_session(conn, :access_token, access_token)
  end
end
