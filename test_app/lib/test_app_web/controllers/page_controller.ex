defmodule TestAppWeb.PageController do
  use TestAppWeb, :controller

  def home(conn, _params) do
    user = KeenAuth.current_user(conn)

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>KeenAuth Test App</title></head>
    <body style="font-family: sans-serif; max-width: 800px; margin: 50px auto; padding: 20px;">
      <h1>KeenAuth Test App</h1>

      #{if user do
        """
        <div style="background: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2>Welcome, #{user.display_name || user.email}!</h2>
          <p><strong>Email:</strong> #{user.email}</p>
          <p><strong>User ID:</strong> #{user.user_id}</p>
          <p><a href="/dashboard">Go to Dashboard</a></p>
          <p><a href="/auth/azure_ad/delete">Sign Out</a></p>
        </div>
        """
      else
        """
        <div style="background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2>Not signed in</h2>
          <p><a href="/login">Go to Login</a></p>
        </div>
        """
      end}

      <h3>Test Links</h3>
      <ul>
        <li><a href="/auth/azure_ad/new">Sign in with Azure AD</a></li>
        <li><a href="/auth/github/new">Sign in with GitHub</a></li>
        <li><a href="/dashboard">Dashboard (protected)</a></li>
        <li><a href="/profile">Profile (protected)</a></li>
      </ul>

      <h3>Configuration Status</h3>
      <pre style="background: #f5f5f5; padding: 15px; border-radius: 4px;">#{inspect(Application.get_env(:test_app, :keen_auth, []), pretty: true)}</pre>
    </body>
    </html>
    """)
  end

  def login(conn, _params) do
    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>Login - KeenAuth Test</title></head>
    <body style="font-family: sans-serif; max-width: 400px; margin: 100px auto; padding: 20px; text-align: center;">
      <h1>Sign In</h1>

      <div style="margin: 30px 0;">
        <a href="/auth/azure_ad/new" style="display: block; padding: 15px; margin: 10px 0; background: #0078d4; color: white; text-decoration: none; border-radius: 4px;">
          Sign in with Azure AD
        </a>

        <a href="/auth/github/new" style="display: block; padding: 15px; margin: 10px 0; background: #333; color: white; text-decoration: none; border-radius: 4px;">
          Sign in with GitHub
        </a>
      </div>

      <p><a href="/">Back to Home</a></p>
    </body>
    </html>
    """)
  end

  def dashboard(conn, _params) do
    user = conn.assigns[:current_user]

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>Dashboard - KeenAuth Test</title></head>
    <body style="font-family: sans-serif; max-width: 800px; margin: 50px auto; padding: 20px;">
      <h1>Dashboard</h1>
      <p style="color: green;">You are authenticated!</p>

      <h3>Current User</h3>
      <pre style="background: #f5f5f5; padding: 15px; border-radius: 4px;">#{inspect(user, pretty: true)}</pre>

      <h3>Session Tokens</h3>
      <ul>
        <li><strong>Access Token:</strong> #{if KeenAuth.Storage.get_access_token(conn), do: "Present (#{String.length(KeenAuth.Storage.get_access_token(conn) || "")} chars)", else: "None"}</li>
        <li><strong>ID Token:</strong> #{if KeenAuth.Storage.get_id_token(conn), do: "Present", else: "None"}</li>
        <li><strong>Refresh Token:</strong> #{if KeenAuth.Storage.get_refresh_token(conn), do: "Present", else: "None"}</li>
        <li><strong>Provider:</strong> #{KeenAuth.Storage.get_provider(conn) || "None"}</li>
      </ul>

      <p><a href="/">Home</a> | <a href="/auth/delete">Sign Out</a></p>
    </body>
    </html>
    """)
  end

  def profile(conn, _params) do
    user = conn.assigns[:current_user]

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>Profile - KeenAuth Test</title></head>
    <body style="font-family: sans-serif; max-width: 800px; margin: 50px auto; padding: 20px;">
      <h1>Profile</h1>

      <table style="width: 100%; border-collapse: collapse;">
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>User ID</strong></td><td>#{user.user_id}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Username</strong></td><td>#{user.username || "N/A"}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Display Name</strong></td><td>#{user.display_name}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Email</strong></td><td>#{user.email}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Roles</strong></td><td>#{inspect(user.roles)}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Permissions</strong></td><td>#{inspect(user.permissions)}</td></tr>
      </table>

      <p style="margin-top: 20px;"><a href="/">Home</a> | <a href="/dashboard">Dashboard</a></p>
    </body>
    </html>
    """)
  end
end
