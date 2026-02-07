defmodule KeenAuth.AuthenticationController do
  @moduledoc """
  Handles the OAuth authentication flow for KeenAuth.

  This controller provides the core endpoints for OAuth authentication:
  - `new/2` - Initiates the OAuth flow by redirecting to the provider
  - `callback/2` - Handles the OAuth callback from the provider
  - `delete/2` - Signs out the user

  ## Usage

  You can use this controller directly via `KeenAuth.authentication_routes/0` or create
  your own controller that uses this module:

      defmodule MyAppWeb.AuthController do
        use KeenAuth.AuthenticationController

        # Override any callback as needed
        def callback(conn, params) do
          # Custom logic before
          result = super(conn, params)
          # Custom logic after
          result
        end
      end

  ## Authentication Flow

  1. User visits `/auth/:provider/new`
  2. Controller redirects to OAuth provider with authorization URL
  3. Provider redirects back to `/auth/:provider/callback`
  4. Controller processes the callback through the pipeline:
     - **Strategy** fetches user data from provider
     - **Mapper** normalizes the user data
     - **Processor** handles business logic (validation, database, etc.)
     - **Storage** persists the session
  5. User is redirected to the original destination
  """

  use Phoenix.Controller

  alias KeenAuth.Helpers.Binary
  alias KeenAuth.Helpers.InputValidator
  alias KeenAuth.Mapper
  alias KeenAuth.Processor
  alias KeenAuth.Storage
  alias KeenAuth.Strategy
  alias KeenAuth.Helpers.RequestHelpers
  alias Plug.Conn

  require Logger

  @callback new(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()
  @callback callback(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()
  @callback delete(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()

  @type tokens_map() :: %{
          optional(:access_token) => binary(),
          optional(:id_token) => binary(),
          optional(:refresh_token) => binary()

          # TODO: Make sure that other fields like expiration are included here as well
        }

  @type oauth_callback_response :: %{
          user: KeenAuth.User.t() | map(),
          token: tokens_map()
        }

  defmacro __using__(_opts \\ []) do
    quote do
      use Phoenix.Controller

      @behaviour unquote(__MODULE__)

      def new(conn, params), do: unquote(__MODULE__).new(conn, params)
      def callback(conn, params), do: unquote(__MODULE__).callback(conn, params)
      def delete(conn, params), do: unquote(__MODULE__).delete(conn, params)

      defoverridable unquote(__MODULE__)
    end
  end

  @doc """
  Initiates the OAuth flow by redirecting to the provider's authorization URL.

  Stores session parameters and optional redirect URL, then redirects the user
  to the OAuth provider for authentication.
  """
  def new(conn, %{"provider" => provider} = params) do
    with {:ok, provider} <- InputValidator.validate_provider(provider),
         {:ok, %{session_params: session_params, url: url}} <- get_authorization_uri(conn, Binary.to_atom(provider)) do
      conn
      |> put_session(:session_params, session_params)
      |> maybe_put_redirect_to(params)
      |> redirect(external: url)
    end
  end

  @doc """
  Handles the OAuth callback from the provider.

  Processes the authentication response through the full pipeline:
  1. Validates the OAuth callback and fetches user data
  2. Maps the raw user data to a normalized format
  3. Processes the user through custom business logic
  4. Stores the authentication in the configured storage

  On success, redirects the user to their original destination.
  """
  def callback(conn, %{"provider" => provider} = params) do
    with {:ok, provider} <- InputValidator.validate_provider(provider) do
      {_, params} = Map.split(params, ["provider"])
      provider = Binary.to_atom(provider)
      {conn, session_params} = get_and_delete_session(conn, :session_params)

      with {:ok, %{user: raw_user} = oauth_result} <- make_callback_back(conn, provider, params, session_params),
           mapped_user = map_user(conn, provider, raw_user),
           {:ok, conn, user, oauth_result} <- process(conn, provider, mapped_user, oauth_result),
           {:ok, conn} <- store(conn, provider, user, oauth_result) do
        RequestHelpers.redirect_back(conn, params)
      end
    end
  end

  @doc """
  Signs out the user by delegating to the processor's `sign_out/3` callback.

  If a provider is specified in params, uses that provider. Otherwise,
  retrieves the provider from storage. Redirects back if no user is signed in.
  """
  def delete(conn, %{"provider" => provider} = params) do
    with {:ok, provider} <- InputValidator.validate_provider(provider) do
      storage = Storage.current_storage(conn)
      provider = Binary.to_atom(provider)
      processor = Processor.current_processor(conn, provider)

      with user when not is_nil(user) <- storage.current_user(conn) do
        processor.sign_out(conn, provider, params)
      else
        nil ->
          RequestHelpers.redirect_back(conn, params)
      end
    end
  end

  def delete(conn, params) do
    storage = Storage.current_storage(conn)
    provider = storage.get_provider(conn)
    processor = Processor.current_processor(conn, provider)

    with user when not is_nil(user) <- storage.current_user(conn) do
      processor.sign_out(conn, provider, params)
    else
      nil ->
        RequestHelpers.redirect_back(conn, params)
    end
  end

  @spec map_user(Conn.t(), atom(), map()) :: KeenAuth.User.t()
  def map_user(conn, provider, user) do
    mod = Mapper.current_mapper(conn, provider)

    mod.map(provider, user)
  end

  @spec process(Conn.t(), atom(), KeenAuth.User.t() | map(), any) :: any
  def process(conn, provider, mapped_user, oauth_result) do
    mod = Processor.current_processor(conn, provider)

    mod.process(conn, provider, mapped_user, oauth_result)
  end

  @spec store(Plug.Conn.t(), atom(), KeenAuth.User.t() | map(), oauth_callback_response()) :: any
  def store(conn, provider, mapped_user, oauth_response) do
    mod = Storage.current_storage(conn)

    mod.store(conn, provider, mapped_user, oauth_response)
  end

  @spec maybe_put_redirect_to(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def maybe_put_redirect_to(conn, params) do
    redirect_to = Map.get(params, "redirect_to")

    if not is_nil(redirect_to) do
      put_session(conn, :redirect_to, redirect_to)
    else
      conn
    end
  end

  # ==== OAuth flow

  @spec get_authorization_uri(Conn.t(), atom()) :: {:ok, %{session_params: map(), url: binary()}}
  def get_authorization_uri(conn, provider) do
    strategy = Strategy.current_strategy!(conn, provider)

    strategy[:strategy].authorize_url(strategy[:config])
  end

  @spec make_callback_back(Conn.t(), atom(), map(), map()) :: {:ok, oauth_callback_response()}
  def make_callback_back(conn, provider, params, session_params \\ %{}) do
    strategy = Strategy.current_strategy!(conn, provider)

    auth_params = Keyword.get(strategy[:config], :authorization_params, [])

    config =
      strategy[:config]
      |> Keyword.put(:session_params, session_params)
      |> Keyword.put(
        :authorization_params,
        Keyword.update(auth_params, :scope, "offline_access", fn scope -> "offline_access " <> scope end)
      )

    strategy[:strategy].callback(config, params)
  end

  defp get_and_delete_session(conn, key) do
    value = get_session(conn, key)
    conn = delete_session(conn, key)

    {conn, value}
  end
end
