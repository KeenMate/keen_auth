defmodule KeenAuth.AuthenticationController do
  use Phoenix.Controller

  alias KeenAuth.Helpers.Binary
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

  def new(conn, %{"provider" => provider} = params) do
    with {:ok, %{session_params: session_params, url: url}} <- get_authorization_uri(conn, Binary.to_atom(provider)) do
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

    with {:ok, %{user: raw_user} = oauth_result} <- make_callback_back(conn, provider, params, session_params),
         mapped_user = map_user(conn, provider, raw_user),
         {:ok, conn, user, oauth_result} <- process(conn, provider, mapped_user, oauth_result),
         {:ok, conn} <- store(conn, provider, user, oauth_result) do
      RequestHelpers.redirect_back(conn, params)
    end
  end

  def delete(conn, %{"provider" => provider} = params) do
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

    auth_params = Assent.Config.get(strategy[:config], :authorization_params, [])

    config =
      strategy[:config]
      |> Assent.Config.put(:session_params, session_params)
      |> Assent.Config.put(
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
