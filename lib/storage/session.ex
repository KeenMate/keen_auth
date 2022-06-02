defmodule KeenAuth.Storage.Session do
  @behaviour KeenAuth.Storage

  alias KeenAuth.Config

  import Plug.Conn, only: [put_session: 3, get_session: 2, delete_session: 2]

  @impl true
  def store(conn, provider, %{user: user, token: tokens}) do
    conn =
      conn
      |> put_provider(provider)
      |> put_access_token(provider, tokens["access_token"])
      |> put_current_user(user)

    {:ok, conn}
  end

  @impl true
  def current_user(conn) do
    get_session(conn, :current_user)
  end

  @impl true
  def authenticated?(conn) do
    false
  end

  @impl true
  def get_roles(conn) do
    case get_session(conn, :access_claims) do
      nil ->
        # Maybe raise error of unauthenticated user?
        []

      claims ->

    end
  end

  @impl true
  def get_access_token(conn) do
    get_session(conn, :access_token)
  end

  @impl true
  def get_id_token(conn) do
    get_session(conn, :id_token)
  end

  @impl true
  def get_refresh_token(conn) do
    get_session(conn, :refresh_token)
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

  def put_provider(conn, nil) do
    delete_session(conn, :provider)
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

  def put_access_token(conn, provider \\ nil, access_token \\ nil)

  def put_access_token(conn, _provider, nil) do
    conn
    |> delete_session(:access_claims)
    |> delete_session(:access_token)
  end

  def put_access_token(conn, provider, access_token) do
    token_mod = Config.get_token(provider)
    with {:ok, claims} <- token_mod.verify(access_token) do
      conn
      |> put_session(:access_claims, claims)
      |> put_session(:access_token, access_token)
    end
  end
end
