defmodule TestAppWeb.Router do
  use TestAppWeb, :router

  require KeenAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # KeenAuth pipeline - stores config in connection
  pipeline :authentication do
    plug KeenAuth.Plug, otp_app: :test_app
  end

  # Fetch user for protected routes
  pipeline :require_auth do
    plug KeenAuth.Plug.FetchUser
    plug KeenAuth.Plug.RequireAuthenticated, redirect: "/login"
  end

  # Public routes
  scope "/", TestAppWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/login", PageController, :login
  end

  # Authentication routes (OAuth flow)
  scope "/auth" do
    pipe_through [:browser, :authentication]

    # This adds:
    # GET  /auth/:provider/new      - Start OAuth flow
    # GET  /auth/:provider/callback - OAuth callback
    # GET  /auth/:provider/delete   - Sign out
    KeenAuth.authentication_routes()
  end

  # Protected routes (require authentication)
  scope "/", TestAppWeb do
    pipe_through [:browser, :authentication, :require_auth]

    get "/dashboard", PageController, :dashboard
    get "/profile", PageController, :profile
  end
end
