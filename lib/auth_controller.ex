defmodule KeenAuth.AuthController do
  @callback new(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()
  @callback callback(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()
  @callback delete(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()

  use Phoenix.Controller

  alias KeenAuth.Helpers.Binary
  alias KeenAuth.Storage

  require Logger

  @defeault_user_mapper KeenAuth.UserMappers.Common
  @defeault_processor KeenAuth.Processor

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

      def new(conn, opts), do: unquote(__MODULE__).new(conn, opts)
      def callback(conn, opts), do: unquote(__MODULE__).callback(conn, opts)
      def delete(conn, opts), do: unquote(__MODULE__).delete(conn, opts)

      defoverridable unquote(__MODULE__)
    end
  end

  def new(conn, %{"provider" => provider} = params) do
    with {:ok, %{session_params: session_params, url: url}} <- get_authorization_uri(Binary.to_atom(provider)) do
      conn
      |> put_session(:session_params, session_params)
      |> maybe_put_redirect_to(params)
      |> redirect(external: url)
    end
  end

  def callback(conn, %{"provider" => provider} = params) do
    {_, params} = Map.split(params, ["provider"])
    provider = Binary.to_atom(provider)
    {conn, session_params} = get_and_delete_session(conn, :session_params)

    with {:ok, %{user: user} = oauth_result} <- make_callback_back(provider, params, session_params),
         user <- map_user(provider, user),
         oauth_result <- Map.put(oauth_result, :user, user),
         {:ok, conn, oauth_result} <- process(conn, provider, oauth_result),
         {:ok, conn} <- store(conn, provider, oauth_result) do

      redirect_back(conn, params)
    end
  end

  def delete(conn, params) do
    store = Storage.get_store()

    with user when not is_nil(user) <- store.current_user(conn) do
      conn
      |> store.delete()
      |> redirect_back(params)
    else
      nil ->
        redirect_back(conn, params)
    end
  end

  @spec map_user(atom(), map()) :: KeenAuth.User.t()
  def map_user(provider, user) do
    mod =
      get_key_from_provider_config(provider, :mapper) || @defeault_user_mapper

    mod.map(provider, user)
  end

  @spec process(any, atom(), any) :: any
  def process(conn, provider, oauth_result) do
    mod =
      get_key_from_provider_config(provider, :processor) || @defeault_processor

    mod.process(conn, provider, oauth_result)
  end

  @spec store(Plug.Conn.t(), atom(), oauth_callback_response()) :: any
  def store(conn, provider, oauth_response) do
    Storage.get_store().store(conn, provider, oauth_response)
  end

  @spec redirect_back(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirect_back(conn, params \\ %{}) do
    redirect_to =
      get_session(conn, :redirect_to)
      || params["redirect_to"]
      || "/"
      |> IO.inspect(label: "Redirecting to")

    conn
    |> delete_session(:redirect_to)
    |> redirect(to: redirect_to)
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

  @spec get_authorization_uri(atom()) :: {:ok, %{session_params: map(), url: binary()}}
  def get_authorization_uri(provider) do
    strategy = get_strategy!(provider)

    strategy[:strategy].authorize_url(strategy[:config])
  end

  @spec make_callback_back(atom(), map(), map()) :: {:ok, oauth_callback_response()}
  def make_callback_back(provider, params, session_params \\ %{}) do
    strategy = get_strategy!(provider)

    auth_params = Assent.Config.get(strategy[:config], :authorization_params, [])
    config =
      strategy[:config]
      |> Assent.Config.put(:session_params, session_params)
      |> Assent.Config.put(:authorization_params, Keyword.update(auth_params, :scope, "offline_access", fn scope -> "offline_access " <> scope end))
      |> IO.inspect(label: "Final config")

    strategy[:strategy].callback(config, params)
  end

  @spec get_key_from_provider_config(atom(), atom()) :: any
  def get_key_from_provider_config(provider, key) do
    strategy = get_strategy!(provider)

    strategy[key]
  end

  @spec get_strategy!(atom()) :: keyword()
  def get_strategy!(provider) do
    Application.get_env(:keen_auth, :strategies)[provider] || raise "No provider configuration for #{provider}"
  end

  defp get_and_delete_session(conn, key) do
    value = get_session(conn, key)
    conn = delete_session(conn, key)

    {conn, value}
  end
end
