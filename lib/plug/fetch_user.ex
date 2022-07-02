defmodule KeenAuth.Plug.FetchUser do
  @moduledoc """
  Fetches current user using storage from config and assigns it to conn
  """

  @behaviour Plug

  alias KeenAuth.Storage

  import Plug.Conn, only: [assign: 3]

  @impl true
  def init(_opts) do
    nil
  end

  @impl true
  def call(conn, _opts) do
    if Storage.authenticated?(conn) do
      conn
      |> assign(:current_user, Storage.current_user(conn))
      # |> assign(:roles, storage.get_roles(conn))
    else
      conn
    end
  end
end
