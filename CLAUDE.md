# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KeenAuth is an Elixir library that facilitates OpenID authentication flow throughout Phoenix applications. It provides OAuth integration with providers like Azure AD, GitHub, and Facebook, as well as email-based authentication.

**Core Philosophy**: KeenAuth implements a "super simple yet super powerful" pipeline approach. Like Unix pipes for authentication, small focused components can be combined in powerful ways. Each stage (Strategy → Mapper → Processor → Storage) can be as simple or sophisticated as needed.

**Pipeline Power Examples**:
- **Mapper**: Can simply normalize fields OR enrich with Graph API calls, fetch user groups, manager info, etc.
- **Processor**: Can pass data through OR implement complex validation, database lookups, role assignments, audit logging
- **Storage**: Can use basic sessions OR multi-layer persistence (database + session + JWT)

**Current Branch**: Working on `prod` branch (renamed from master) - the stable production branch.

## Development Commands

### Dependencies and Setup
- `mix deps.get` - Install dependencies
- `mix deps.compile` - Compile dependencies

### Testing and Quality
- `mix test` - Run all tests
- `mix format` - Format code according to project standards
- `mix format --check-formatted` - Check if code is properly formatted

### Compilation and Building
- `mix compile` - Compile the project
- `mix clean` - Clean generated files

### Documentation
- `mix docs` - Generate documentation (via ex_doc dependency)

## Core Architecture

### Main Components

**Pipeline Components** (the heart of KeenAuth's power):
1. **Strategy** - Handles OAuth provider protocols (via Assent library)
2. **Mapper** - Normalizes user data and can enrich with external API calls
3. **Processor** - Business logic hub for validation, user creation, role assignment
4. **Storage** - Flexible persistence layer (session/database/JWT/custom)

**Authentication Flow Infrastructure**:
- `KeenAuth.Plug` - Main plug that stores configuration in connection
- `KeenAuth.AuthenticationController` - Handles OAuth flow endpoints (`/auth/:provider/new`, `/auth/:provider/callback`, `/auth/:provider/delete`)
- `KeenAuth.EmailAuthenticationController` - Handles email-based authentication

**Authorization System**: Provides plugs for protecting routes:
- `KeenAuth.Plug.FetchUser` - Fetches current user from storage
- `KeenAuth.Plug.RequireAuthenticated` - Requires authentication
- `KeenAuth.Plug.Authorize.*` - Authorization by roles, groups, permissions

### Configuration Structure

The library expects configuration in the consuming application:

```elixir
config :keen_auth,
  strategies: [
    provider_name: [
      strategy: Assent.Strategy.ProviderName,
      mapper: KeenAuth.Mappers.ProviderName,
      processor: MyApp.Auth.Processor,  # Custom processor
      config: [
        client_id: "...",
        client_secret: "...",
        redirect_uri: "..."
      ]
    ]
  ]
```

### Route Integration

Applications use the `KeenAuth.authentication_routes()` macro to add auth routes:

```elixir
scope "/auth" do
  pipe_through :authentication
  KeenAuth.authentication_routes()
end
```

### Key Behaviors

- `KeenAuth.Processor` - Custom authentication processing logic
- `KeenAuth.Storage` - Custom user/session storage
- `KeenAuth.Mapper` - Custom user data mapping

## Documentation

**README.md Features**:
- Comprehensive pipeline documentation with practical examples
- Mermaid diagrams that render on GitHub showing:
  - Basic pipeline flow (Strategy → Mapper → Processor → Storage)
  - Advanced Azure AD + Graph API example with sequence diagram
- Real-world code examples for each pipeline stage
- Multiple storage options (Session, Database, JWT)
- Route protection and authorization examples

## Documentation Status

**Well-Documented Modules**:
- ✅ `KeenAuth` (main module) - Complete @moduledoc with architecture diagram
- ✅ `KeenAuth.Processor` - Complete @moduledoc, callback docs, and function docs
- ✅ `KeenAuth.Storage` - Complete @moduledoc with implementation examples
- ✅ `KeenAuth.Config` - All functions have @doc and @spec
- ✅ `KeenAuth.Plug.FetchUser` - Has @moduledoc
- ✅ `KeenAuth.AuthenticationController` - Complete @moduledoc and @doc for public functions
- ✅ `KeenAuth.Plug` - Complete @moduledoc
- ✅ `KeenAuth.EmailAuthenticationController` - Complete @moduledoc with flow diagram
- ✅ `KeenAuth.EmailAuthenticationHandler` - Complete @moduledoc and @callback docs
- ✅ `KeenAuth.User` - Complete @moduledoc with examples

**Need Documentation**:
- ❌ Individual mapper modules (AzureAD, Github, Facebook - partially done)
- ❌ Authorization plugs (Authorize.Roles, Authorize.Groups, etc.)

## Important Notes

- The library uses session storage by default but can be configured for ETS or custom storage
- Code formatting follows 140-character line length (see `.formatter.exs`)
- Tests have compilation issues with `ssl_verify_fun` dependency (missing `public_key.hrl`) but core functionality works
- The pipeline approach allows starting simple and scaling complexity as needed
- Each pipeline stage is independent and can be customized without affecting others
- Core behavior modules (Processor, Storage) now have comprehensive documentation with examples

## Branch Information

**Current Branch**: `prod` (renamed from master) - the stable production branch containing the latest features and improvements.