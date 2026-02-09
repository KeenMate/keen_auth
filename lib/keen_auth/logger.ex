defmodule KeenAuth.Logger do
  @moduledoc """
  Categorized logging for KeenAuth with compile-time purging support.

  ## Categories

  - `AUTH` - Authentication flow (authorize redirect, callback handling)
  - `MAPPER` - User data mapping and normalization
  - `PROCESSOR` - Business logic processing
  - `STORAGE` - Session/token storage operations
  - `SECURITY` - Security validations (redirect URLs, input validation)
  - `CONFIG` - Configuration loading and validation

  ## Usage

  ```elixir
  require KeenAuth.Logger, as: Log

  Log.debug(:auth, "Starting OAuth flow", provider: :github)
  Log.info(:mapper, "Mapped user", user_id: user.id)
  Log.warn(:security, "Rejected redirect URL", url: url)
  Log.error(:processor, "Authentication failed", reason: reason)
  ```

  ## Compile-Time Purging

  Debug logs can be completely removed from production builds by configuring
  Logger's compile-time purge level in your `config/prod.exs`:

  ```elixir
  config :logger,
    compile_time_purge_matching: [
      [level_lower_than: :info]
    ]
  ```

  This removes all `:debug` level logs at compile time - zero runtime overhead.

  ## Runtime Control

  You can also control log levels at runtime:

  ```elixir
  # Set KeenAuth logs to debug level
  Logger.put_module_level(KeenAuth.Logger, :debug)

  # Or configure in config
  config :logger, :keen_auth,
    level: :debug
  ```
  """

  require Logger

  @type category :: :auth | :mapper | :processor | :storage | :security | :config

  @categories %{
    auth: "AUTH",
    mapper: "MAPPER",
    processor: "PROCESSOR",
    storage: "STORAGE",
    security: "SECURITY",
    config: "CONFIG"
  }

  @doc """
  Logs a debug message with category prefix.

  Debug logs are typically stripped from production builds via compile_time_purge_matching.
  """
  defmacro debug(category, message, metadata \\ []) do
    prefix = Map.get(@categories, category, "KEEN_AUTH")

    quote do
      require Logger
      Logger.debug(fn -> "[KeenAuth:#{unquote(prefix)}] #{unquote(message)}" end, unquote(metadata))
    end
  end

  @doc """
  Logs an info message with category prefix.
  """
  defmacro info(category, message, metadata \\ []) do
    prefix = Map.get(@categories, category, "KEEN_AUTH")

    quote do
      require Logger
      Logger.info(fn -> "[KeenAuth:#{unquote(prefix)}] #{unquote(message)}" end, unquote(metadata))
    end
  end

  @doc """
  Logs a warning message with category prefix.
  """
  defmacro warn(category, message, metadata \\ []) do
    prefix = Map.get(@categories, category, "KEEN_AUTH")

    quote do
      require Logger
      Logger.warning(fn -> "[KeenAuth:#{unquote(prefix)}] #{unquote(message)}" end, unquote(metadata))
    end
  end

  @doc """
  Logs an error message with category prefix.
  """
  defmacro error(category, message, metadata \\ []) do
    prefix = Map.get(@categories, category, "KEEN_AUTH")

    quote do
      require Logger
      Logger.error(fn -> "[KeenAuth:#{unquote(prefix)}] #{unquote(message)}" end, unquote(metadata))
    end
  end
end
