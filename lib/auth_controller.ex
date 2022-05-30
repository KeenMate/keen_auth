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

      import unquote(__MODULE__)

      def new(conn, opts), do: unquote(__MODULE__).new(conn, opts)
      def callback(conn, opts), do: unquote(__MODULE__).callback(conn, opts)
      def delete(conn, opts), do: unquote(__MODULE__).delete(conn, opts)
      def normalize(conn, user), do: unquote(__MODULE__).normalize(conn, user)

      defoverridable [new: 2, delete: 2, callback: 2, normalize: 2]
    end
  end

  def new(conn, %{"provider" => provider}) do
    with {:ok, %{session_params: session_params, url: url}} <- request(String.to_existing_atom(provider)) do
      conn
      |> put_session(:session_params, session_params)
      |> redirect(external: url)
    end
  end

  def callback(conn, %{"provider" => provider} = opts) do
    {_, params} = Map.split(opts, ["provider"])

    with {:ok, %{user: user, token: token}} <- make_callback(String.to_existing_atom(provider), params, get_session(conn, :session_params)) do
      conn
      |> Session.new(normalize(conn, user), token)
      |> redirect(to: "/")
    end
  end

  def delete(conn, _opts) do
    with user when not is_nil(user) <- Session.current_user(conn) do
      conn
      |> Session.delete()
      |> redirect(to: "/")
    end
  end

  def normalize(_conn, user) do
    user
  end

  # =============================================================================

  def request(provider) do
    strategy = get_strategy!(provider)

    strategy[:strategy].authorize_url(strategy[:config])
  end

  def make_callback(provider, params, session_params \\ %{}) do
    strategy = get_strategy!(provider)
    config =
      strategy[:config]
      |> Assent.Config.put(:session_params, session_params)

    strategy[:strategy].callback(config, params) |> IO.inspect(label: "CAllback result")
  end

  def get_strategy!(provider) do
    Application.get_env(:keen_auth, :strategies)[provider] || raise "No provider configuration for #{provider}"
  end
end
