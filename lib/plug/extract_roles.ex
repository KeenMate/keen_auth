defmodule KeenAuth.Plug.ExtractRoles do
  @moduledoc """
  If access claims are available for conn then extracts roles claim into separate conn's private variable
  """

  require Logger

  alias Plug.Conn
  alias KeenAuth.Request

  def init(opts) do
    %{client: Keyword.fetch!(opts, :client)}
  end

  def call(conn, %{client: client}) do
    with true <- Request.has_claims?(conn, client),
         claims <- Request.get_claims(conn, client),
         {:ok, roles} <- extract_roles_from_claims(claims, client_id(client)) do
      Logger.debug("[ExtractRoles] Saving roles to assigns: #{inspect(roles)}")

      Conn.assign(conn, :user_roles, roles)
    else
      err ->
        Logger.debug("[ExtractRoles] Couldn't extract roles: #{inspect(err)}")

        conn
    end
  end

  defp client_id(client) when is_atom(client) do
    Application.get_env(:keen_auth, :clients)
    |> get_in([client, :oidc, :client_id])
  end

  defp client_id(client) when is_binary(client), do: client

  defp extract_roles_from_claims(claims, client_id) do
    case get_in(claims, ["resource_access", client_id, "roles"]) do
      nil -> {:error, :no_roles_found}
      roles -> {:ok, roles}
    end
  end
end
