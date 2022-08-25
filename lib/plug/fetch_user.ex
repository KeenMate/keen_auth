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
    conn
    |> assign(:current_user, Storage.current_user(conn))
  end
end
