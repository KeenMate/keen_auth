defmodule KeenAuth.Storage.Session do
  @behaviour KeenAuth.Storage

  # alias KeenAuth.Token

  import Plug.Conn, only: [put_session: 3, get_session: 2, delete_session: 2]

  @impl true
  def store(conn, provider, mapped_user, oauth_response) do
    conn =
      conn
      |> put_provider(provider)
      |> put_tokens(provider, oauth_response[:token])
      # TODO save oath response roles and groups
      # |> put_provider_roles(provider, oauth_response[:user][:roles])
      |> put_current_user(provider, mapped_user)

    {:ok, conn}
  end

  @impl true
  def current_user(conn) do
    get_session(conn, :current_user)
  end

  @impl true
  def authenticated?(conn) do
    current_user(conn) != nil
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

  @impl true
  def get_provider(conn) do
    get_session(conn, :provider)
  end

  @impl true
  def put_provider(conn, provider \\ nil)

  def put_provider(conn, nil) do
    delete_session(conn, :provider)
  end

  def put_provider(conn, provider) do
    put_session(conn, :provider, provider)
  end

  @impl true
  def put_current_user(conn, provider \\ nil, user \\ nil)

  def put_current_user(conn, _provider, nil) do
    delete_session(conn, :current_user)
  end

  def put_current_user(conn, _provider, user) do
    put_session(conn, :current_user, user)
  end

  @impl true
  def put_tokens(conn, provider, tokens) do
    conn
    |> put_access_token(provider, tokens["access_token"])
    |> put_id_token(provider, tokens["id_token"])
    |> put_refresh_token(provider, tokens["refresh_token"])
  end

  def put_access_token(conn, provider \\ nil, token \\ nil)

  def put_access_token(conn, _provider, nil) do
    conn
    |> delete_session(:access_claims)
    |> delete_session(:access_token)
  end

  def put_access_token(conn, _provider, token) do
    put_session(conn, :access_token, token)
  end

  def put_id_token(conn, provider \\ nil, token \\ nil)

  def put_id_token(conn, _provider, nil) do
    delete_session(conn, :id_token)
  end

  def put_id_token(conn, _provider, token) do
    put_session(conn, :id_token, token)
  end

  @spec put_refresh_token(Plug.Conn.t(), any, any) :: Plug.Conn.t()
  def put_refresh_token(conn, provider \\ nil, token \\ nil)

  def put_refresh_token(conn, _provider, nil) do
    delete_session(conn, :refresh_token)
  end

  def put_refresh_token(conn, _provider, token) do
    put_session(conn, :refresh_token, token)
  end
end
