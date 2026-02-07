defmodule KeenAuth.Helpers.RequestHelpers do
  @moduledoc """
  Helper functions for handling HTTP requests in authentication flows.
  """

  import Phoenix.Controller, only: [redirect: 2]

  alias KeenAuth.Helpers.RedirectValidator
  alias KeenAuth.Plug.AuthSession

  @doc """
  Redirects the user back to their original destination after authentication.

  The redirect URL is resolved in order of priority:
  1. Auth session `:redirect_to` value
  2. `redirect_to` parameter from request params
  3. Falls back to "/"

  All redirect URLs are validated through `KeenAuth.Helpers.RedirectValidator`
  to prevent open redirect vulnerabilities.
  """
  @spec redirect_back(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirect_back(conn, params \\ %{}) do
    {conn, session_redirect} = AuthSession.get_and_delete(conn, :redirect_to)

    raw_redirect = session_redirect || params["redirect_to"]
    redirect_to = RedirectValidator.validate(raw_redirect, conn)

    redirect(conn, to: redirect_to)
  end
end
