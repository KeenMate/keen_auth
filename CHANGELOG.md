# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - Unreleased

### Changed
- Clarified OAuth scopes documentation: `openid profile email` are required, `offline_access` is optional (for refresh tokens)
- Added CHANGELOG.md to hex package

## [1.0.1] - 2026-02-09 (published)

### Fixed
- Fixed type reference in Processor docs (`oauth_callback_result` → `oauth_callback_response`)
- Fixed ExDoc admonition syntax (GitHub-style → ExDoc format)

### Changed
- Enhanced README with philosophy section and "Start Simple, Scale Up" examples
- Added "What Each Stage Does" section explaining data flow through pipeline
- ExDoc configuration with module grouping (Core, Pipeline, Plugs, etc.)
- Added Mermaid diagram support for local docs preview
- Improved architecture diagram with proper Mermaid flowchart

## [1.0.0] - 2026-02-09 (published)

First stable release after years of production use across multiple projects.

### Breaking Changes
- **Elixir 1.14+ required** (was 1.10+)
- **Assent 0.3.0+** - updated from 0.2.x (OIDC-based strategies, type changes)
- **Removed Ecto dependency** - `KeenAuth.User.new/1` rewritten without Ecto.Changeset
- **Removed ssl_verify_fun and certifi** - obsolete with modern Erlang/OTP

### Added
- **Dual-cookie session architecture** (`KeenAuth.Plug.AuthSession`)
  - Separate encrypted cookie for OAuth state (nonce, PKCE, redirect URL)
  - Auto-cleared after successful authentication
  - Prevents session fixation via automatic session ID regeneration
  - Configurable for HTTP dev (`SameSite=Lax`) or HTTPS prod (`SameSite=None; Secure`)
- **Default OIDC scopes**: Automatically adds `openid profile email offline_access` when no scopes specified - prevents empty user data from providers like Azure AD/Entra
- **Session storage options**: `storage_options: [store_tokens: false]` to prevent cookie overflow (tokens can be large)
- **Dynamic provider listing**: `KeenAuth.list_providers/1` returns configured providers with metadata (label, icon, color, path) for dynamically rendering login pages
  - Accepts `conn` (after KeenAuth.Plug pipeline) or `otp_app` atom (for login pages before auth)
  - Supports `enabled: false` to hide unconfigured providers from the list
  - Also added `KeenAuth.provider_names/1` for simpler name-only lists
- **Provider rendering helper**: `KeenAuth.render_providers/2` takes providers and a render callback for flexible HTML generation
  - Allows different button styles (large login buttons, small navbar links) from the same provider list
- **Categorized logging**: `KeenAuth.Logger` module with compile-time purging support
  - Categories: AUTH, MAPPER, PROCESSOR, STORAGE, SECURITY, CONFIG
  - All logs at `:debug` level by default (except security warnings at `:warn`)
  - Debug logs can be completely removed from production builds via `compile_time_purge_matching`
  - Zero runtime overhead in production when purged
- **Azure AD/Entra mapper** now accepts `:aad`, `:azure_ad`, and `:entra` provider atoms
- `KeenAuth.User` now includes `:groups` field
- Comprehensive documentation for all public modules
- `test_app/` - minimal Phoenix app for testing and development
- `CLAUDE.md` for AI-assisted development guidance
- `CHANGELOG.md` to track project changes
- `SECURITY.md` documenting security considerations and rate limiting examples

### Security
- **Open redirect prevention**: Added `KeenAuth.Helpers.RedirectValidator` with configurable callback
  - Default: only relative URLs allowed
  - Custom: configure `:redirect_validator` callback for database/allowlist validation
- **Input length limits**: Added `KeenAuth.Helpers.InputValidator`
  - Redirect URLs: max 2048 bytes
  - Provider names: max 64 bytes, alphanumeric/hyphen/underscore only
- Changed `redirect(external:)` to `redirect(to:)` for validated URLs

### Changed
- Updated `README.md` with pipeline documentation and Mermaid diagrams
- Improved documentation for `KeenAuth.Processor`, `KeenAuth.Storage`, and `KeenAuth.Config`
- `redirect_back/2` now validates URLs before redirecting
- Updated Joken to ~> 2.6
- Updated ex_doc to ~> 0.34

### Removed
- `auth_action_fallback` configuration option (can be implemented by overriding the controller)
- Ecto dependency (was only used for User.new/1 changeset casting)
- ssl_verify_fun dependency (obsolete, Erlang 25+ has native SSL verification)
- certifi dependency (only needed with ssl_verify_fun)
- `new-vision` branch (merged into `prod`)

## [0.2.2] - 2024

### Added
- Option to specify `action_fallback` for authentication controller (later removed)
- Documentation updates after years of production use

### Fixed
- Getting redirect option from `RequireAuthenticated` plug opts
- Assigning `current_user` correctly
- `require_authenticated` now checks `current_user` from assigns instead of storage

### Changed
- Updated required Phoenix version to >= 1.6.7

## [0.2.1] - Previous

### Fixed
- Missing provider parameter handling
- Function name typo
- Missing parse of provider parameter
- Brought back `/delete` endpoint

## [0.2.0] - Previous

### Added
- Initial "new-vision" architecture with pipeline approach
- Strategy, Mapper, Processor, Storage pipeline components
- Support for Azure AD, GitHub, Facebook providers
- Email-based authentication
- Authorization plugs (roles, groups, permissions)
- Session-based storage
- JWT token support
