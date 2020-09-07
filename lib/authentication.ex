defmodule KeenAuth.Authentication do
  def login_uri(client, params \\ %{}) do
    OpenIDConnect.authorization_uri(client, params)
  end

  def logout_uri(client, redirect_to) do
    logout_endpoint =
      GenServer.call(:openid_connect, {:discovery_document, client})
      |> Map.get("end_session_endpoint")

    logout_endpoint <> "?redirect_uri=" <> redirect_to
  end
end
