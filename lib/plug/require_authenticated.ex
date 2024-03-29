defmodule KeenAuth.Plug.RequireAuthenticated do
  @behaviour Plug

  alias Plug.Conn
  alias KeenAuth.Storage
  alias KeenAuth.Config

  import Conn
  import Phoenix.Controller, only: [redirect: 2]

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    if KeenAuth.authenticated?(conn) do
      conn
    else
      handle_unauthenticated(conn, opts)
    end
  end

  def handle_unauthenticated(%Conn{request_path: request_path} = conn, opts) do
    application_redirect =
      if Keyword.has_key?(opts, :redirect) do
        opts[:redirect]
      else
        config_redirect(conn)
      end

    cond do
      is_function(application_redirect) ->
        conn
        |> redirect(to: application_redirect.(conn, request_path))
        |> halt()

      is_binary(application_redirect) ->
        conn
        |> redirect(to: application_redirect)
        |> halt()

      true ->
        conn
        |> KeenAuth.Plug.AuthorizationErrorHandler.call(:unauthorized)
        |> halt()
    end
  end

  defp config_redirect(conn) do
    conn
    |> KeenAuth.Plug.fetch_config()
    |> Config.get(:unauthorized_redirect)
  end
end
