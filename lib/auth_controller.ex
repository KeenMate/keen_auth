defmodule KeenAuth.AuthController do
  @callback new(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()
  @callback callback(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()
  @callback delete(conn :: Plug.Conn.t(), any()) :: Plug.Conn.t()

  @callback normalize(conn :: Plug.Conn.t(), user :: map()) :: any()

  use Phoenix.Controller

  alias KeenAuth.Session

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

  def new(conn, %{"provider" => provider}) do
    with {:ok, %{session_params: session_params, url: url}} <- request(String.to_existing_atom(provider)) do
      conn
      |> put_session(:session_params, session_params |> IO.inspect(label: "Session params"))
      |> redirect(external: url)
    end
  end

  def callback(conn, %{"provider" => provider} = opts) do
    {_, params} = Map.split(opts, ["provider"])

    with {:ok, %{user: user, token: token}} <- make_callback(String.to_existing_atom(provider), params, get_session(conn, :session_params)),
         user <- map_user(provider, user),
         {:ok, conn, user} <- process(conn, provider, user),
         {:ok, conn} <- store(conn, provider, user) do

      # use redirect_uri (from querystring as well)
      # put into session (dont forget to clean from session)
      # |> redirect(to: "/")
    end
  end

  def delete(conn, _opts) do
    with user when not is_nil(user) <- Session.current_user(conn) do
      conn
      |> Session.delete()
      |> redirect(to: "/")
    end
  end

  defp map_user(provider, user) do
    mod =
      get_key_from_provider_config(provider, :mapper) || KeenAuth.UserMapper

    mod.map(provider, user)
  end

  defp process(conn, provider, user) do
    mod =
      get_key_from_provider_config(provider, :processor) || KeenAuth.UserProcessor

    mod.process(conn, provider, user)
  end

  defp store(conn, provider, user) do
    mod =
      get_key_from_provider_config(provider, :storage) || KeenAuth.UserStorage

    mod.store(conn, provider, user)
  end

  # =============================================================================


  def request(provider) do
    strategy = get_strategy!(provider)

    strategy[:strategy].authorize_url(strategy[:config])
  end

  def make_callback(provider, params, session_params \\ %{}) do
    strategy = get_strategy!(provider)

    auth_params = Assent.Config.get(strategy[:config], :authorization_params, [])
    config =
      strategy[:config]
      |> Assent.Config.put(:session_params, session_params)
      |> Assent.Config.put(:authorization_params, Keyword.update(auth_params, :scope, "offline_access", fn scope -> "offline_access " <> scope end))
      |> IO.inspect(label: "Final config")

    strategy[:strategy].callback(config, params) |> IO.inspect(label: "CAllback result")
  end

  def get_key_from_provider_config(provider, key) do
    strategy = get_strategy!(provider)

    strategy[key]
  end

  def get_strategy!(provider) do
    Application.get_env(:keen_auth, :strategies)[provider] || raise "No provider configuration for #{provider}"
  end
end
