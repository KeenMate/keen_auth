defmodule KeenAuth.Plug.RequireAuthenticated do
  @behaviour Plug

  alias Plug.Conn
  alias KeenAuth.Config

  import Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts) do
    [
      storage: Config.get_storage(),
      redirect: Application.get_env(:keen_auth, :unauthorized_redirect)
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
    application_redirect = opts[:redirect]

    cond do
      is_function(application_redirect) ->
        redirect(conn, to: application_redirect.(conn, request_path))

      is_binary(application_redirect) ->
        redirect(conn, to: application_redirect)

      true ->
        conn
        |> KeenAuth.Plug.AuthorizationErrorHandler.call(:unauthorized)
        |> halt()
    end
  end
end
