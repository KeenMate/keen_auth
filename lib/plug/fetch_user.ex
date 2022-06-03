defmodule KeenAuth.Plug.FetchUser do
  @behaviour Plug

  alias KeenAuth.Config

  import Plug.Conn, only: [assign: 3]

  @impl true
  def init(_opts) do
    %{
      storage: Config.get_storage()
    }
  end

  @impl true
  def call(conn, opts) do
    storage = opts.storage
    if storage.authenticated?(conn) do
      conn
      |> assign(:current_user, storage.current_user(conn))
      |> assign(:roles, storage.get_roles(conn))
    else
      conn
    end
  end
end
