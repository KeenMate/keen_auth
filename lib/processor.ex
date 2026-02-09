defmodule KeenAuth.Processor do
  @moduledoc """
  Defines the processor behavior for handling authentication business logic.

  Processors are the business logic hub in KeenAuth's pipeline architecture. They receive
  normalized user data from mappers and can implement custom validation, user creation,
  role assignment, auditing, and other business-specific logic.

  ## Pipeline Stage

  The processor sits between the mapper and storage in the authentication flow:

  ```
  Strategy → Mapper → **Processor** → Storage
  ```

  ## Flexibility

  Processors can be as simple or sophisticated as needed:

  - **Simple**: Pass data through unchanged
  - **Advanced**: Database lookups, validation, user creation, role assignment, auditing

  ## Example Implementation

      defmodule MyApp.Auth.Processor do
        @behaviour KeenAuth.Processor

        def process(conn, provider, mapped_user, oauth_response) do
          with {:ok, user} <- find_or_create_user(mapped_user),
               :ok <- validate_permissions(user),
               {:ok, user} <- assign_roles(user, oauth_response) do
            {:ok, conn, user, oauth_response}
          else
            {:error, reason} ->
              conn
              |> put_flash(:error, "Authentication failed")
              |> redirect(to: "/login")
          end
        end

        def sign_out(conn, provider, params) do
          conn
          |> KeenAuth.Storage.delete()
          |> redirect(to: "/")
        end
      end

  ## Configuration

  Specify your processor in the strategy configuration:

      config :keen_auth,
        strategies: [
          azure_ad: [
            processor: MyApp.Auth.Processor,
            # ... other config
          ]
        ]
  """

  alias KeenAuth.AuthenticationController
  alias KeenAuth.Strategy

  @default_processor KeenAuth.Processor.Default

  @doc """
  Processes the authenticated user and OAuth response.

  This callback is called after the user data has been normalized by the mapper.
  It's where you implement your application's business logic for handling
  authenticated users.

  ## Parameters

  - `conn` - The Plug connection
  - `provider` - The OAuth provider atom (e.g., `:azure_ad`, `:github`)
  - `mapped_user` - User data normalized by the mapper
  - `response` - The complete OAuth response including tokens

  ## Return Values

  - `{:ok, conn, user, response}` - Success, proceed to storage
  - `conn` - Halt processing (e.g., redirect to error page)

  ## Example

      def process(conn, :azure_ad, mapped_user, oauth_response) do
        case create_or_update_user(mapped_user) do
          {:ok, user} -> {:ok, conn, user, oauth_response}
          {:error, _} -> redirect(conn, to: "/login?error=invalid_user")
        end
      end
  """
  @callback process(
              conn :: Plug.Conn.t(),
              provider :: atom(),
              mapped_user :: KeenAuth.User.t() | map(),
              response :: AuthenticationController.oauth_callback_response() | nil
            ) ::
              {:ok, Plug.Conn.t(), KeenAuth.User.t() | map(), AuthenticationController.oauth_callback_response() | nil} | Plug.Conn.t()

  @doc """
  Handles user sign out.

  This callback is called when a user signs out. It should clean up any
  user-specific data and redirect appropriately.

  ## Parameters

  - `conn` - The Plug connection
  - `provider` - The OAuth provider atom or binary
  - `params` - Request parameters (may include redirect destination)

  ## Return Value

  - `conn` - The modified connection (typically with a redirect)

  ## Example

      def sign_out(conn, _provider, params) do
        conn
        |> clear_user_session()
        |> redirect(to: params["redirect_to"] || "/")
      end
  """
  @callback sign_out(conn :: Plug.Conn.t(), provider :: binary(), params :: map()) :: Plug.Conn.t()

  defmacro __using__(_params \\ nil) do
    quote do
      @behaviour unquote(__MODULE__)

      def process(conn, provider, mapped_user, oauth_response), do: unquote(__MODULE__).process(conn, provider, mapped_user, oauth_response)
      def sign_out(conn, provider, params), do: unquote(__MODULE__).sign_out(conn, provider, params)

      defoverridable unquote(__MODULE__)
    end
  end

  @doc """
  Delegates to the configured processor for the given provider.

  This function looks up the processor configured for the specific provider
  and calls its `process/4` function.
  """
  def process(conn, provider, mapped_user, oauth_response) do
    current_processor(conn, provider).process(conn, provider, mapped_user, oauth_response)
  end

  @doc """
  Delegates to the configured processor for sign out.

  This function looks up the processor configured for the specific provider
  and calls its `sign_out/3` function.
  """
  def sign_out(conn, provider, params) do
    current_processor(conn, provider).signout(conn, provider, params)
  end

  @doc """
  Gets the processor module for the given provider.

  Fetches the configuration from the connection and returns the processor
  module configured for the provider.
  """
  def current_processor(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_processor(provider)
  end

  @doc """
  Extracts the processor module from the configuration.

  Returns the configured processor for the provider, or the default processor
  if none is configured.
  """
  def get_processor(config, provider) do
    Strategy.get_strategy(config, provider)[:processor] || @default_processor
  end
end
