defmodule TestApp.Auth.EmailHandler do
  @moduledoc """
  Email authentication handler for testing KeenAuth.

  This is a simple implementation that uses hardcoded test users.
  In a real app, you would check against a database with hashed passwords.

  ## Test Users

  | Email              | Password  |
  |--------------------|-----------|
  | admin@test.com     | admin123  |
  | user@test.com      | user123   |
  """

  @behaviour KeenAuth.EmailAuthenticationHandler

  require Logger

  # Hardcoded test users (in real app, use database + password hashing)
  @test_users %{
    "admin@test.com" => %{
      password: "admin123",
      user: %{
        "sub" => "email-1",
        "email" => "admin@test.com",
        "name" => "Test Admin",
        "preferred_username" => "admin",
        "roles" => ["admin", "user"],
        "groups" => ["administrators"]
      }
    },
    "user@test.com" => %{
      password: "user123",
      user: %{
        "sub" => "email-2",
        "email" => "user@test.com",
        "name" => "Test User",
        "preferred_username" => "testuser",
        "roles" => ["user"],
        "groups" => ["users"]
      }
    }
  }

  @impl true
  def authenticate(_conn, %{"email" => email, "password" => password}) do
    Logger.info("[EmailHandler] Authentication attempt for: #{email}")

    case Map.get(@test_users, String.downcase(email)) do
      %{password: ^password, user: user} ->
        Logger.info("[EmailHandler] Authentication successful for: #{email}")
        {:ok, user}

      %{password: _wrong} ->
        Logger.warning("[EmailHandler] Invalid password for: #{email}")
        {:error, :invalid_password}

      nil ->
        Logger.warning("[EmailHandler] User not found: #{email}")
        {:error, :user_not_found}
    end
  end

  def authenticate(_conn, params) do
    Logger.warning("[EmailHandler] Missing email or password in params: #{inspect(Map.keys(params))}")
    {:error, :missing_credentials}
  end

  @impl true
  def handle_authenticated(conn, user) do
    Logger.info("[EmailHandler] User authenticated: #{user.email}")
    conn
  end

  @impl true
  def handle_unauthenticated(conn, params, error) do
    Logger.warning("[EmailHandler] Authentication failed: #{inspect(error)}")

    message =
      case error do
        {:error, :invalid_password} -> "Invalid password"
        {:error, :user_not_found} -> "User not found"
        {:error, :missing_credentials} -> "Please provide email and password"
        _ -> "Authentication failed"
      end

    conn
    |> Phoenix.Controller.put_flash(:error, message)
    |> Phoenix.Controller.redirect(to: params["redirect_to"] || "/login")
  end
end
