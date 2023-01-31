defmodule KeenAuth.Processor.Default do
  use KeenAuth.Processor

  alias KeenAuth.Storage
  alias KeenAuth.Helpers.RequestHelpers

  @impl true
  def process(conn, _provider, mapped_user, oauth_response) do
    {:ok, conn, mapped_user, oauth_response}
  end

  @impl true
  def sign_out(conn, _provider, params) do
    storage = Storage.current_storage(conn)

    conn
    |> storage.delete()
    |> RequestHelpers.redirect_back(params)
  end
end
