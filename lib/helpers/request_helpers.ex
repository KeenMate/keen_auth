defmodule KeenAuth.Helpers.RequestHelpers do
  @moduledoc """
  Helper functions for handling HTTP requests in authentication flows.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias KeenAuth.Helpers.RedirectValidator

  @doc """
  Redirects the user back to their original destination after authentication.

  The redirect URL is resolved in order of priority:
  1. Session `:redirect_to` value
  2. `redirect_to` parameter from request params
  3. Falls back to "/"

  All redirect URLs are validated through `KeenAuth.Helpers.RedirectValidator`
  to prevent open redirect vulnerabilities.
  """
  @spec redirect_back(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirect_back(conn, params \\ %{}) do
    raw_redirect =
      get_session(conn, :redirect_to) ||
        params["redirect_to"]

    redirect_to = RedirectValidator.validate(raw_redirect, conn)

    conn
    |> delete_session(:redirect_to)
    |> redirect(to: redirect_to)
  end
end
