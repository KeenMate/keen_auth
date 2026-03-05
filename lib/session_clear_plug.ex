defmodule KeenAuth.SessionClearPlug do
  @moduledoc """
  A Plug that clears the authentication session and returns 204 No Content.

  Designed for JS clients (LiveView hard-block, SPA logout) to invalidate
  the session without a redirect. Expects a POST request.

  ## Router Setup

      scope "/auth" do
        pipe_through [:browser, :authentication]
        post "/clear", KeenAuth.SessionClearPlug, []
      end

  JS calls it via:

      fetch("/auth/clear", {
        method: "POST",
        headers: {"x-csrf-token": csrfToken}
      })
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> KeenAuth.Storage.delete()
    |> configure_session(drop: true)
    |> put_resp_content_type("application/json")
    |> send_resp(204, "")
    |> halt()
  end
end
