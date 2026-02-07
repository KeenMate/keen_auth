defmodule TestApp.Auth.Processor do
  @moduledoc """
  Custom processor for testing KeenAuth.

  This processor logs authentication events and can be extended
  to test various scenarios like:
  - Database user creation
  - Role assignment
  - Custom validation
  """

  @behaviour KeenAuth.Processor

  require Logger

  @impl true
  def process(conn, provider, mapped_user, oauth_result) do
    Logger.info("""
    [TestApp.Auth.Processor] Authentication successful!
      Provider: #{inspect(provider)}
      User: #{mapped_user.email}
      Display Name: #{mapped_user.display_name}
    """)

    # Here you would typically:
    # 1. Look up or create user in database
    # 2. Assign roles based on provider claims
    # 3. Log the authentication event

    # For testing, we just pass through
    {:ok, conn, mapped_user, oauth_result}
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
