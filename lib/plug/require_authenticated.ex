defmodule KeenAuth.Plug.RequireAuthenticated do
  @behaviour Plug

  alias Plug.Conn
  alias KeenAuth.Config

  import Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts) do
    [
      storage: Config.get_storage(),
      login_path: Application.get_env(:keen_auth, :login_path)
    ]
    |> Keyword.merge(opts)
  end

  def call(conn, opts) do
    storage = opts[:storage]

    if storage.authenticated?(conn) do
      conn
    else
      handle_unauthenticated(conn, opts)
    end
  end

  def handle_unauthenticated(%Conn{request_path: request_path} = conn, opts) do
    login_path = opts[:login_path]

    cond do
      is_function(login_path) ->
        redirect(conn, to: login_path.(conn, request_path))

      is_binary(login_path) ->
        redirect(conn, to: login_path)

      true ->
        conn
        |> KeenAuth.Plug.AuthorizationErrorHandler.call(:unauthorized)
        |> halt()
    end
  end
end
