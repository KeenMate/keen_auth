defmodule KeenAuth.Plug.RequireAuthenticated do
  @behaviour Plug

  alias KeenAuth.Config

  import Plug.Conn
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
      if login_path = opts[:login_path] do
        cond do
          is_function(login_path) ->
            redirect(conn, to: login_path.(conn))

          is_binary(login_path) ->
            redirect(conn, to: login_path)
        end
      else
        put_status(conn, 401)
      end
    end
  end
end
