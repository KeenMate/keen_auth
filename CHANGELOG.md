# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - Unreleased

### Breaking Changes
- **Elixir 1.14+ required** (was 1.10+)
- **Assent 0.3.0+** - updated from 0.2.x (OIDC-based strategies, type changes)
- **Removed Ecto dependency** - `KeenAuth.User.new/1` rewritten without Ecto.Changeset
- **Removed ssl_verify_fun and certifi** - obsolete with modern Erlang/OTP

### Added
- Comprehensive documentation for `KeenAuth.AuthenticationController` (@moduledoc, @doc)
- Comprehensive documentation for `KeenAuth.Plug` (@moduledoc)
- Comprehensive documentation for `KeenAuth.User` (@moduledoc, @doc)
- `KeenAuth.User` now includes `:groups` field
- Azure AD mapper now accepts both `:aad` and `:azure_ad` provider atoms
- `CLAUDE.md` for AI-assisted development guidance
- `CHANGELOG.md` to track project changes
- `SECURITY.md` documenting security considerations and rate limiting examples
- `test_app/` - minimal Phoenix app for testing KeenAuth

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
