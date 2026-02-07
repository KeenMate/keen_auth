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

  # Browser without CSRF - for OAuth callbacks from external providers
  pipeline :browser_no_csrf do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  # KeenAuth pipeline - stores config in connection
  pipeline :authentication do
    plug KeenAuth.Plug, otp_app: :test_app
  end

  # Optional auth - fetch user if logged in, but don't require it
  pipeline :maybe_auth do
    plug KeenAuth.Plug.FetchUser
  end

  # Fetch user for protected routes
  pipeline :require_auth do
    plug KeenAuth.Plug.FetchUser
    plug KeenAuth.Plug.RequireAuthenticated, redirect: "/login"
  end

  # Public routes with optional user display
  scope "/", TestAppWeb do
    pipe_through [:browser, :authentication, :maybe_auth]

    get "/", PageController, :home
  end

  # Login page (no auth fetching needed)
  scope "/", TestAppWeb do
    pipe_through :browser

    get "/login", PageController, :login
  end

  # Email authentication (with CSRF - form from our app)
  scope "/auth/email" do
    pipe_through [:browser, :authentication]

    post "/new", KeenAuth.EmailAuthenticationController, :new
  end

  # OAuth routes (no CSRF - callbacks come from external providers)
  scope "/auth" do
    pipe_through [:browser_no_csrf, :authentication]

    scope "/:provider" do
      get "/new", KeenAuth.AuthenticationController, :new
      get "/callback", KeenAuth.AuthenticationController, :callback
      post "/callback", KeenAuth.AuthenticationController, :callback
      get "/delete", KeenAuth.AuthenticationController, :delete
    end

    get "/delete", KeenAuth.AuthenticationController, :delete
  end

  # Protected routes (require authentication)
  scope "/", TestAppWeb do
    pipe_through [:browser, :authentication, :require_auth]

    get "/dashboard", PageController, :dashboard
    get "/profile", PageController, :profile
    get "/debug", PageController, :debug
  end
end
