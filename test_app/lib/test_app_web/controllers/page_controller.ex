defmodule TestAppWeb.PageController do
  use TestAppWeb, :controller

  def home(conn, _params) do
    user = KeenAuth.current_user(conn)
    providers = get_configured_providers()

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
          <p><strong>Provider:</strong> #{KeenAuth.Storage.get_provider(conn) || "unknown"}</p>
          <div style="margin-top: 15px;">
            <a href="/dashboard" style="display: inline-block; padding: 10px 20px; background: #4caf50; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Dashboard</a>
            <a href="/profile" style="display: inline-block; padding: 10px 20px; background: #2196f3; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Profile</a>
            <a href="/debug" style="display: inline-block; padding: 10px 20px; background: #9c27b0; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px;">Debug</a>
            <a href="/auth/delete" style="display: inline-block; padding: 10px 20px; background: #f44336; color: white; text-decoration: none; border-radius: 4px;">Sign Out</a>
          </div>
        </div>
        """
      else
        """
        <div style="background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2>Not signed in</h2>
          <p>Choose a sign-in method below to get started.</p>
          <a href="/login" style="display: inline-block; padding: 10px 20px; background: #ff9800; color: white; text-decoration: none; border-radius: 4px;">Go to Login</a>
        </div>
        """
      end}

      <h3>Quick Links</h3>
      <ul>
        <li><a href="/login">Sign in with Email</a> (admin@test.com / admin123)</li>
        <li><a href="/auth/entra/new">Sign in with Microsoft Entra</a></li>
        <li><a href="/auth/github/new">Sign in with GitHub</a></li>
        <li><a href="/dashboard">Dashboard (protected)</a></li>
        <li><a href="/profile">Profile (protected)</a></li>
      </ul>

      <h3>Configured Providers</h3>
      <ul>
        #{Enum.map_join(providers, "\n", fn {name, strategy} -> "<li><strong>#{name}</strong> - #{strategy}</li>" end)}
      </ul>
    </body>
    </html>
    """)
  end

  defp get_configured_providers do
    config = Application.get_env(:test_app, :keen_auth, [])
    strategies = Keyword.get(config, :strategies, [])

    Enum.map(strategies, fn {name, opts} ->
      strategy = Keyword.get(opts, :strategy, "email")
      {name, strategy}
    end)
  end

  def login(conn, _params) do
    flash_error = Phoenix.Flash.get(conn.assigns[:flash] || %{}, :error)

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

      <!-- OAuth Providers -->
      <div style="text-align: center;">
        <p style="color: #666; margin-bottom: 15px;">Or sign in with:</p>

        <a href="/auth/entra/new" style="display: block; padding: 15px; margin: 10px 0; background: #0078d4; color: white; text-decoration: none; border-radius: 4px;">
          Microsoft Entra
        </a>

        <a href="/auth/github/new" style="display: block; padding: 15px; margin: 10px 0; background: #333; color: white; text-decoration: none; border-radius: 4px;">
          GitHub
        </a>
      </div>

      <p style="text-align: center; margin-top: 20px;"><a href="/">Back to Home</a></p>
    </body>
    </html>
    """)
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
end
