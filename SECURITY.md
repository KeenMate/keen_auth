# Security Considerations

This document outlines known security considerations and recommendations for applications using KeenAuth.

## Addressed Issues

### 1. Open Redirect Prevention (FIXED)

KeenAuth now validates all redirect URLs through `KeenAuth.Helpers.RedirectValidator`.

**Default behavior:** Only relative URLs (starting with `/`) are allowed.

**Custom validation:** Configure a callback for custom validation logic:

```elixir
config :keen_auth,
  redirect_validator: &MyApp.Auth.validate_redirect/2
```

The callback receives `(url, conn)` and returns `{:ok, url}` or `:error`:

```elixir
# Allow specific domains
def validate_redirect(url, _conn) do
  uri = URI.parse(url)
  allowed = ["myapp.com", "app.myapp.com", nil]  # nil = relative URL
  if uri.host in allowed, do: {:ok, url}, else: :error
end

# Database-backed allowlist
def validate_redirect(url, _conn) do
  uri = URI.parse(url)
  if AllowedDomains.exists?(uri.host), do: {:ok, url}, else: :error
end
```

### 2. Input Length Limits (FIXED)

KeenAuth now validates input lengths:

| Input | Max Length |
|-------|------------|
| Redirect URL | 2048 bytes |
| Provider name | 64 bytes |

Provider names are also validated to only contain alphanumeric characters, hyphens, and underscores.

### 3. Rate Limiting (Application Responsibility)

**Location:** OAuth endpoints, Email authentication

KeenAuth does not include built-in rate limiting because:
- Applications may use infrastructure-level rate limiting (nginx, CloudFlare, AWS WAF)
- Different applications have different rate limiting requirements
- Rate limiting libraries (Hammer, PlugAttack) are easy to integrate

**Note:** Email authentication includes timing attack mitigation via `Process.sleep(Enum.random(100..300//10))`.

#### Recommended Rate Limits

| Endpoint | Route | Limit | Window |
|----------|-------|-------|--------|
| OAuth start | `/auth/:provider/new` | 10-20 | 1 minute |
| OAuth callback | `/auth/:provider/callback` | 10-20 | 1 minute |
| Sign out | `/auth/:provider/delete` | 10 | 1 minute |
| Email login | `/auth/email` | 5 | 1 minute |

#### Implementation with Hammer

Add Hammer to your dependencies:

```elixir
# mix.exs
{:hammer, "~> 6.1"}
```

Create a rate limiting plug:

```elixir
defmodule MyAppWeb.Plugs.AuthRateLimiter do
  @behaviour Plug

  import Plug.Conn

  # 10 requests per minute per IP
  @limit 10
  @window_ms 60_000

  def init(opts), do: opts

  def call(conn, _opts) do
    case check_rate(conn) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(429, "Too many requests. Please try again later.")
        |> halt()
    end
  end

  defp check_rate(conn) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    Hammer.check_rate("auth:#{ip}", @window_ms, @limit)
  end
end
```

Add the plug to your authentication pipeline:

```elixir
# router.ex
pipeline :authentication do
  plug MyAppWeb.Plugs.AuthRateLimiter  # Add rate limiting
  plug KeenAuth.Plug, otp_app: :my_app
end

scope "/auth" do
  pipe_through [:browser, :authentication]
  KeenAuth.authentication_routes()
end
```

#### Implementation with PlugAttack

```elixir
# mix.exs
{:plug_attack, "~> 0.4"}

# lib/my_app_web/plugs/auth_rate_limiter.ex
defmodule MyAppWeb.Plugs.AuthRateLimiter do
  use PlugAttack

  rule "auth rate limit", conn do
    if String.starts_with?(conn.request_path, "/auth") do
      throttle(conn.remote_ip, period: 60_000, limit: 10)
    end
  end
end
```

#### Infrastructure-Level Rate Limiting

If you prefer infrastructure-level rate limiting:

**Nginx:**
```nginx
limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/m;

location /auth {
    limit_req zone=auth burst=5 nodelay;
    # ... proxy config
}
```

**CloudFlare:** Use Rate Limiting Rules in the dashboard to limit `/auth/*` endpoints.

### 4. Session Storage Size (LOW)

**Location:** `lib/storage/session.ex`

**Issue:** OAuth tokens (access_token, id_token, refresh_token) are stored directly in session. Some providers return large tokens (especially with many claims/groups), which could:
- Exceed cookie size limits (4KB)
- Cause session storage issues

**Recommendation:**
- Use server-side session storage (ETS, Redis, database)
- Or implement a custom Storage that only stores essential data

### 5. JWT Configuration (LOW)

**Location:** `lib/token/jwt.ex`

**Issue:** The JWT module uses bare `use Joken.Config` without explicit configuration. Applications must configure Joken properly.

**Recommendation:** Ensure your application configures Joken with:
```elixir
config :joken, default_signer: [
  signer_alg: "HS256",  # or RS256 for asymmetric
  key_octet: "your-secret-key-at-least-256-bits"
]
```

### 6. Provider Name Handling (LOW)

**Location:** `lib/helpers/binary.ex`

**Issue:** Uses `String.to_existing_atom/1` which will raise `ArgumentError` if the atom doesn't exist. While this prevents atom table exhaustion attacks, it could cause unhandled crashes.

**Note:** This is generally safe as provider names should be pre-defined in configuration.

## Security Best Practices for Implementers

1. **Always validate redirect URLs** - Implement allowlist validation in your Processor
2. **Use HTTPS only** - Ensure all OAuth redirect URIs use HTTPS
3. **Implement rate limiting** - Protect authentication endpoints from abuse
4. **Use server-side sessions** - Avoid cookie size limitations and token exposure
5. **Validate OAuth state** - The library uses Assent which handles state validation
6. **Keep dependencies updated** - Regularly update Assent and other dependencies
7. **Log authentication events** - Implement audit logging in your Processor
8. **Set secure cookie flags** - Ensure session cookies have `secure: true`, `http_only: true`, `same_site: :lax`

## Reporting Security Issues

If you discover a security vulnerability, please report it by:
1. Opening a private security advisory on GitHub
2. Or emailing the maintainers directly

Please do not open public issues for security vulnerabilities.
