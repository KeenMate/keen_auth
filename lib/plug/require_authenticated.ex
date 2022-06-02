defmodule KeenAuth.Plug.RequireAuthenticated do
  @behaviour Plug

  alias KeenAuth.Config

  import Plug.Conn

  def init(opts) do
    %{
      storage: Config.get_storage()
    }
    |> Map.merge(opts)
  end

  def call(conn, opts) do
    storage = opts[:storage]

    if storage.authenticated?(conn) do
      conn
    else
      conn
      |> put_status(401)
    end
  end
end
