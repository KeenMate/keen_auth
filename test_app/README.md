# KeenAuth Test App

A minimal Phoenix application for testing KeenAuth functionality.

## Setup

1. Install dependencies:

```bash
cd test_app
mix deps.get
```

2. Configure OAuth credentials:

```bash
# Copy the example config and fill in your credentials
cp config/.local.exs.example config/.local.exs
# Edit config/.local.exs with your OAuth credentials
```

The `.local.exs` file is gitignored, so your secrets won't be committed.

3. Start the server:

```bash
mix phx.server
```

4. Visit http://localhost:4000

## OAuth Provider Setup

### Azure AD / Entra ID

1. Go to [Azure Portal](https://portal.azure.com) > Azure Active Directory > App registrations
2. Create new registration
3. Set redirect URI to `http://localhost:4000/auth/azure_ad/callback`
4. Create a client secret
5. Copy Client ID, Client Secret, and Tenant ID

### GitHub

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create new OAuth App
3. Set callback URL to `http://localhost:4000/auth/github/callback`
4. Copy Client ID and Client Secret

## Test Routes

| Route | Description |
|-------|-------------|
| `/` | Home page - shows auth status |
| `/login` | Login page with provider buttons |
| `/auth/:provider/new` | Start OAuth flow |
| `/auth/:provider/callback` | OAuth callback |
| `/auth/:provider/delete` | Sign out |
| `/dashboard` | Protected - requires auth |
| `/profile` | Protected - shows user details |

## Testing Checklist

- [ ] OAuth flow completes successfully
- [ ] User data is mapped correctly
- [ ] Session stores user and tokens
- [ ] Protected routes require authentication
- [ ] Sign out clears session
- [ ] Redirect after login works
- [ ] Invalid redirect URLs are rejected
