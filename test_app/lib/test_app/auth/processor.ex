defmodule TestApp.Auth.Processor do
  @moduledoc """
  Custom processor for testing KeenAuth.

  This processor logs authentication events and can be extended
  to test various scenarios like:
  - Database user creation
  - Role assignment
  - Custom validation

  ## Session Security

  KeenAuth automatically handles session security:
  - OAuth state is stored in a namespaced area of the session
  - Session ID is regenerated after successful authentication
  - OAuth state is cleared after use

  If you need custom session handling, you can use:
  - `KeenAuth.Plug.AuthSession.regenerate/1` - regenerate session ID
  - `KeenAuth.Plug.AuthSession.clear/1` - clear auth state
  """

  @behaviour KeenAuth.Processor

  require Logger

  @impl true
  def process(conn, provider, mapped_user, oauth_result) do
    raw_user = oauth_result[:user]
    tokens = oauth_result[:token] || %{}

    # Decode ID token to see claims (without verification - debug only)
    id_token_claims = decode_jwt(tokens["id_token"])

    # Log raw OAuth data for debugging
    Logger.info("""
    ========== [DEBUG] RAW OAUTH RESULT ==========
    Provider: #{inspect(provider)}

    Raw User from Assent (extracted from id_token):
    #{inspect(raw_user, pretty: true, limit: :infinity)}

    ID Token Claims (decoded):
    #{inspect(id_token_claims, pretty: true, limit: :infinity)}

    Mapped User (after KeenAuth.Mapper):
    #{inspect(mapped_user, pretty: true)}

    Token Keys: #{inspect(Map.keys(tokens))}
    ==============================================
    """)

    # Store raw data in session for debug page (small, won't overflow)
    conn =
      conn
      |> Plug.Conn.put_session(:debug_raw_user, raw_user)
      |> Plug.Conn.put_session(:debug_id_token_claims, id_token_claims)

    {:ok, conn, mapped_user, oauth_result}
  end

  # Decode JWT without verification (for debugging only)
  defp decode_jwt(nil), do: nil
  defp decode_jwt(token) when is_binary(token) do
    try do
      [_header, payload, _signature] = String.split(token, ".")

      payload
      |> Base.url_decode64!(padding: false)
      |> Jason.decode!()
    rescue
      _ -> %{"error" => "Failed to decode JWT"}
    end
  end

  @impl true
  def sign_out(conn, provider, params) do
    Logger.info("[TestApp.Auth.Processor] User signing out from #{inspect(provider)}")

    storage = KeenAuth.Storage.current_storage(conn)

    conn
    |> storage.delete()
    |> Phoenix.Controller.redirect(to: params["redirect_to"] || "/")
  end
end
