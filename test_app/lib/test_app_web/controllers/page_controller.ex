defmodule TestAppWeb.PageController do
  use TestAppWeb, :controller

  def home(conn, _params) do
    user = KeenAuth.current_user(conn)
    providers = KeenAuth.list_providers(:test_app)

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>KeenAuth Test App</title></head>
    <body style="font-family: sans-serif; max-width: 800px; margin: 50px auto; padding: 20px;">
      <h1>KeenAuth Test App</h1>

      #{if user do
        is_admin = "admin" in (user.roles || [])
        """
        <div style="background: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2>Welcome, #{user.display_name || user.email}!</h2>
          <p><strong>Email:</strong> #{user.email}</p>
          <p><strong>User ID:</strong> #{user.user_id}</p>
          <p><strong>Provider:</strong> #{KeenAuth.Storage.get_provider(conn) || "unknown"}</p>
          <p><strong>Roles:</strong> #{inspect(user.roles || [])}</p>
          <div style="margin-top: 15px;">
            <a href="/dashboard" style="display: inline-block; padding: 10px 20px; background: #4caf50; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Dashboard</a>
            <a href="/profile" style="display: inline-block; padding: 10px 20px; background: #2196f3; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Profile</a>
            <a href="/debug" style="display: inline-block; padding: 10px 20px; background: #9c27b0; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Debug</a>
            #{if is_admin, do: "<a href=\"/admin\" style=\"display: inline-block; padding: 10px 20px; background: #ff9800; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;\">Admin</a>", else: ""}
            <a href="/auth/delete" style="display: inline-block; padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 4px;">Sign Out</a>
          </div>
        </div>
        """
      else
        oauth_providers = Enum.reject(providers, & &1.name == :email)
        """
        <div style="background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2>Not signed in</h2>
          <p>Choose a sign-in method below to get started.</p>
          <div style="margin-top: 15px;">
            <a href="/login" style="display: inline-block; padding: 10px 20px; background: #ff9800; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Email Login</a>
            #{KeenAuth.render_providers(oauth_providers, &render_small_button/1)}
          </div>
        </div>
        """
      end}

      <h3>Quick Sign In</h3>
      <div style="margin: 15px 0;">
        #{KeenAuth.render_providers(providers, &render_small_button/1)}
      </div>

      <h3>Protected Pages</h3>
      <ul>
        <li><a href="/dashboard">Dashboard</a> (requires login)</li>
        <li><a href="/profile">Profile</a> (requires login)</li>
        <li><a href="/debug">Debug</a> (requires login)</li>
        <li><a href="/admin">Admin Panel</a> (requires admin role)</li>
      </ul>

      <h3>Configured Providers</h3>
      <ul>
        #{Enum.map_join(providers, "\n", fn p ->
          "<li><strong>#{p.name}</strong> - #{p.label} (#{p.color || "no color"})</li>"
        end)}
      </ul>
    </body>
    </html>
    """)
  end

  def login(conn, _params) do
    flash_error = Phoenix.Flash.get(conn.assigns[:flash] || %{}, :error)
    providers = KeenAuth.list_providers(:test_app)
    oauth_providers = Enum.reject(providers, fn p -> p.name == :email end)

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>Login - KeenAuth Test</title></head>
    <body style="font-family: sans-serif; max-width: 400px; margin: 100px auto; padding: 20px;">
      <h1 style="text-align: center;">Sign In</h1>

      #{if flash_error do
      """
      <div style="background: #ffebee; color: #c62828; padding: 10px 15px; border-radius: 4px; margin-bottom: 20px;">
        #{flash_error}
      </div>
      """
    else
      ""
    end}

      <!-- Email/Password Form -->
      <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
        <h3 style="margin-top: 0;">Email Login</h3>
        <form action="/auth/email/new" method="POST">
          <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />

          <div style="margin-bottom: 15px;">
            <label style="display: block; margin-bottom: 5px; font-weight: bold;">Email</label>
            <input type="email" name="email" placeholder="admin@test.com"
                   style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box;" />
          </div>

          <div style="margin-bottom: 15px;">
            <label style="display: block; margin-bottom: 5px; font-weight: bold;">Password</label>
            <input type="password" name="password" placeholder="admin123"
                   style="width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box;" />
          </div>

          <button type="submit"
                  style="width: 100%; padding: 12px; background: #4caf50; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px;">
            Sign in with Email
          </button>
        </form>

        <p style="margin-top: 15px; font-size: 12px; color: #666;">
          <strong>Test accounts:</strong><br/>
          admin@test.com / admin123<br/>
          user@test.com / user123
        </p>
      </div>

      <!-- OAuth Providers (dynamically rendered) -->
      #{if oauth_providers != [] do
        """
        <div style="text-align: center;">
          <p style="color: #666; margin-bottom: 15px;">Or sign in with:</p>
          #{KeenAuth.render_providers(oauth_providers, &render_large_button/1)}
        </div>
        """
      else
        ""
      end}

      <p style="text-align: center; margin-top: 20px;"><a href="/">Back to Home</a></p>
    </body>
    </html>
    """)
  end

  # Large button renderer for login page
  defp render_large_button(provider) do
    color = provider.color || "#333"
    """
    <a href="#{provider.path}" style="display: block; padding: 15px; margin: 10px 0; background: #{color}; color: white; text-decoration: none; border-radius: 4px;">
      #{provider.label}
    </a>
    """
  end

  # Small inline button renderer (example for navbar usage)
  defp render_small_button(provider) do
    color = provider.color || "#333"
    """
    <a href="#{provider.path}" style="display: inline-block; padding: 8px 12px; margin: 0 5px; background: #{color}; color: white; text-decoration: none; border-radius: 4px; font-size: 12px;">
      #{provider.label}
    </a>
    """
  end

  def dashboard(conn, _params) do
    user = conn.assigns[:current_user]
    access_token = KeenAuth.Storage.get_access_token(conn)
    id_token = KeenAuth.Storage.get_id_token(conn)
    refresh_token = KeenAuth.Storage.get_refresh_token(conn)

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>Dashboard - KeenAuth Test</title></head>
    <body style="font-family: sans-serif; max-width: 800px; margin: 50px auto; padding: 20px;">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <h1>Dashboard</h1>
        <div>
          <a href="/debug" style="padding: 10px 20px; background: #9c27b0; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Debug</a>
          <a href="/auth/delete" style="padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 4px;">Sign Out</a>
        </div>
      </div>

      <div style="background: #e8f5e9; padding: 15px; border-radius: 8px; margin: 20px 0;">
        <strong>Authenticated as:</strong> #{user.display_name || user.email}
      </div>

      <h3>Current User</h3>
      <pre style="background: #f5f5f5; padding: 15px; border-radius: 4px; overflow-x: auto;">#{inspect(user, pretty: true)}</pre>

      <h3>Session Info</h3>
      <table style="width: 100%; border-collapse: collapse;">
        <tr style="border-bottom: 1px solid #eee;">
          <td style="padding: 10px;"><strong>Provider</strong></td>
          <td>#{KeenAuth.Storage.get_provider(conn) || "None"}</td>
        </tr>
        <tr style="border-bottom: 1px solid #eee;">
          <td style="padding: 10px;"><strong>Access Token</strong></td>
          <td>#{if access_token, do: "Present (#{String.length(access_token)} chars)", else: "Not stored (cookie mode)"}</td>
        </tr>
        <tr style="border-bottom: 1px solid #eee;">
          <td style="padding: 10px;"><strong>ID Token</strong></td>
          <td>#{if id_token, do: "Present (#{String.length(id_token)} chars)", else: "Not stored (cookie mode)"}</td>
        </tr>
        <tr style="border-bottom: 1px solid #eee;">
          <td style="padding: 10px;"><strong>Refresh Token</strong></td>
          <td>#{if refresh_token, do: "Present", else: "Not stored (cookie mode)"}</td>
        </tr>
      </table>

      <p style="margin-top: 20px;">
        <a href="/">Home</a> |
        <a href="/profile">Profile</a>
      </p>
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
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <h1>Profile</h1>
        <div>
          <a href="/debug" style="padding: 10px 20px; background: #9c27b0; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Debug</a>
          <a href="/auth/delete" style="padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 4px;">Sign Out</a>
        </div>
      </div>

      <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee; width: 150px;"><strong>User ID</strong></td><td>#{user.user_id}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Username</strong></td><td>#{user.username || "N/A"}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Display Name</strong></td><td>#{user.display_name}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Email</strong></td><td>#{user.email}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Roles</strong></td><td>#{inspect(user.roles)}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Groups</strong></td><td>#{inspect(user.groups)}</td></tr>
        <tr><td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>Permissions</strong></td><td>#{inspect(user.permissions)}</td></tr>
      </table>

      <p style="margin-top: 20px;">
        <a href="/">Home</a> |
        <a href="/dashboard">Dashboard</a> |
        <a href="/debug">Debug</a>
      </p>
    </body>
    </html>
    """)
  end

  def debug(conn, _params) do
    user = conn.assigns[:current_user]
    raw_session = Plug.Conn.get_session(conn)

    # Get debug data stored by processor
    raw_user = Plug.Conn.get_session(conn, :debug_raw_user)
    id_token_claims = Plug.Conn.get_session(conn, :debug_id_token_claims)

    # Get actual tokens (now stored in ETS session)
    access_token = KeenAuth.Storage.get_access_token(conn)
    id_token = KeenAuth.Storage.get_id_token(conn)
    refresh_token = KeenAuth.Storage.get_refresh_token(conn)

    # Decode tokens
    access_token_decoded = decode_jwt(access_token)
    id_token_decoded = decode_jwt(id_token)

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Debug - KeenAuth Test</title>
      <style>
        body { font-family: monospace; max-width: 1200px; margin: 20px auto; padding: 20px; }
        pre { background: #1e1e1e; color: #d4d4d4; padding: 15px; border-radius: 4px; overflow-x: auto; white-space: pre-wrap; word-wrap: break-word; }
        h2 { border-bottom: 2px solid #333; padding-bottom: 10px; margin-top: 30px; }
        h3 { color: #666; margin-top: 20px; }
        .section { margin-bottom: 30px; }
        .highlight { background: #2d2d2d; border-left: 4px solid #4caf50; }
        .warning { background: #fff3e0; border-left: 4px solid #ff9800; }
      </style>
    </head>
    <body>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <h1>Debug Session Data</h1>
        <a href="/auth/delete" style="padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 4px;">Sign Out</a>
      </div>

      <div class="section">
        <h2>1. Current User (what KeenAuth stored after mapping)</h2>
        <pre>#{inspect(user, pretty: true, limit: :infinity)}</pre>
      </div>

      <div class="section">
        <h2>2. Raw User from Assent (oauth_result.user)</h2>
        <p style="color: #666;">This is what Assent extracts from the id_token and passes to the Mapper.</p>
        #{if raw_user do
          "<pre class=\"highlight\">#{format_claims(raw_user)}</pre>"
        else
          "<pre class=\"warning\">(not available - login again to capture)</pre>"
        end}
      </div>

      <div class="section">
        <h2>3. ID Token Claims (decoded JWT)</h2>
        <p style="color: #666;">Full claims from Microsoft's id_token.</p>
        #{if id_token_claims do
          "<pre class=\"highlight\">#{format_claims(id_token_claims)}</pre>"
        else
          "<pre class=\"warning\">(not available - login again to capture)</pre>"
        end}
      </div>

      <div class="section">
        <h2>4. Access Token (decoded)</h2>
        #{if access_token_decoded do
          "<pre>#{format_claims(access_token_decoded)}</pre>"
        else
          "<pre class=\"warning\">(not stored)</pre>"
        end}
      </div>

      <div class="section">
        <h2>5. ID Token (decoded from storage)</h2>
        #{if id_token_decoded do
          "<pre>#{format_claims(id_token_decoded)}</pre>"
        else
          "<pre class=\"warning\">(not stored)</pre>"
        end}
      </div>

      <div class="section">
        <h2>6. Refresh Token</h2>
        <pre>#{if refresh_token, do: "Present (#{String.length(refresh_token)} chars)", else: "(not stored)"}</pre>
      </div>

      <div class="section">
        <h2>7. Raw Session Keys</h2>
        <pre>#{inspect(Map.keys(raw_session), pretty: true)}</pre>
      </div>

      <div class="section">
        <h2>8. Provider</h2>
        <pre>#{inspect(KeenAuth.Storage.get_provider(conn))}</pre>
      </div>

      <div class="section" style="background: #e3f2fd; padding: 20px; border-radius: 8px;">
        <h2 style="border: none; margin-top: 0;">The Data Flow</h2>
        <pre style="background: transparent; color: #333;">#{data_flow_diagram()}</pre>
      </div>

      <p style="margin-top: 20px;">
        <a href="/">Home</a> |
        <a href="/dashboard">Dashboard</a> |
        <a href="/profile">Profile</a>
      </p>
    </body>
    </html>
    """)
  end

  defp data_flow_diagram do
    """
    Microsoft Token Endpoint
            ↓
    access_token, id_token, refresh_token
            ↓
    Assent decodes id_token → oauth_result.user (Section 2)
            ↓
    KeenAuth.Mapper.AzureAD → %KeenAuth.User{} (Section 1)
            ↓
    KeenAuth.Storage.Session → Session (ETS)
    """
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

  defp format_claims(nil), do: "(no data)"
  defp format_claims(claims) when is_map(claims) do
    # Format with important claims first
    important = ["sub", "oid", "name", "preferred_username", "email", "upn", "roles", "groups", "given_name", "family_name"]

    {important_claims, other_claims} =
      Enum.split_with(claims, fn {k, _v} -> k in important end)

    formatted_important =
      important_claims
      |> Enum.sort_by(fn {k, _} -> Enum.find_index(important, &(&1 == k)) || 999 end)
      |> Enum.map(fn {k, v} -> "★ #{k}: #{inspect(v)}" end)
      |> Enum.join("\n")

    formatted_other =
      other_claims
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "  #{k}: #{inspect(v)}" end)
      |> Enum.join("\n")

    if formatted_important != "" do
      "=== IMPORTANT CLAIMS ===\n#{formatted_important}\n\n=== OTHER CLAIMS ===\n#{formatted_other}"
    else
      inspect(claims, pretty: true)
    end
  end

  # ============ Admin Pages (requires admin role) ============

  def admin(conn, _params) do
    user = conn.assigns[:current_user]

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>Admin Panel - KeenAuth Test</title></head>
    <body style="font-family: sans-serif; max-width: 800px; margin: 50px auto; padding: 20px;">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <h1>🔐 Admin Panel</h1>
        <a href="/auth/delete" style="padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 4px;">Sign Out</a>
      </div>

      <div style="background: #fff3e0; border-left: 4px solid #ff9800; padding: 15px; margin: 20px 0;">
        <strong>Protected Route!</strong> This page requires the <code>admin</code> role.
        <br><br>
        Your roles: <code>#{inspect(user.roles)}</code>
      </div>

      <div style="background: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h3 style="margin-top: 0;">Welcome, Admin #{user.display_name || user.email}!</h3>
        <p>You have access to admin features because your account has the <code>admin</code> role.</p>
      </div>

      <h3>Admin Actions</h3>
      <ul>
        <li><a href="/admin/settings">Admin Settings</a></li>
        <li><a href="/dashboard">User Dashboard</a> (also accessible to non-admins)</li>
      </ul>

      <h3>Test Authorization</h3>
      <p>Try these scenarios:</p>
      <ul>
        <li><strong>Email admin:</strong> Login with <code>admin@test.com / admin123</code> → Can access this page</li>
        <li><strong>Email user:</strong> Login with <code>user@test.com / user123</code> → Will be denied access</li>
        <li><strong>Entra user:</strong> Any Entra login → Gets admin role automatically (for testing)</li>
      </ul>

      <p style="margin-top: 30px;">
        <a href="/">← Home</a> |
        <a href="/dashboard">Dashboard</a> |
        <a href="/profile">Profile</a>
      </p>
    </body>
    </html>
    """)
  end

  def admin_settings(conn, _params) do
    user = conn.assigns[:current_user]

    html(conn, """
    <!DOCTYPE html>
    <html>
    <head><title>Admin Settings - KeenAuth Test</title></head>
    <body style="font-family: sans-serif; max-width: 800px; margin: 50px auto; padding: 20px;">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <h1>⚙️ Admin Settings</h1>
        <a href="/auth/delete" style="padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 4px;">Sign Out</a>
      </div>

      <div style="background: #e3f2fd; border-left: 4px solid #2196f3; padding: 15px; margin: 20px 0;">
        <strong>Admin Only!</strong> Logged in as: #{user.display_name || user.email}
      </div>

      <h3>Application Settings</h3>
      <div style="background: #f5f5f5; padding: 20px; border-radius: 8px;">
        <p><em>This is a placeholder settings page to demonstrate role-based authorization.</em></p>
        <p>In a real app, you might have:</p>
        <ul>
          <li>User management</li>
          <li>System configuration</li>
          <li>Audit logs</li>
          <li>Feature flags</li>
        </ul>
      </div>

      <p style="margin-top: 30px;">
        <a href="/admin">← Admin Panel</a> |
        <a href="/">Home</a>
      </p>
    </body>
    </html>
    """)
  end
end
