defmodule KeenAuth.EmailAuthenticationController do
  alias KeenAuth.Mapper
  alias KeenAuth.Storage
  alias KeenAuth.Processor
  alias KeenAuth.EmailAuthenticationHandler

  use Phoenix.Controller

  defmacro __using__(_opts \\ []) do
    quote do
      use Phoenix.Controller

      @behaviour unquote(__MODULE__)

      def new(conn, params), do: unquote(__MODULE__).new(conn, params)
      def delete(conn, params), do: unquote(__MODULE__).delete(conn, params)

      defoverridable unquote(__MODULE__)
    end
  end

  # TODO Throttling
  def new(conn, params) do
    provider = :email

    with {:ok, raw_user} <- EmailAuthenticationHandler.authenticate(conn, params),
         response = %{user: raw_user, tokens: nil},
         mapped_user = Mapper.current_mapper(conn, provider).map(raw_user, provider),
         {:ok, conn, user, result} <- Processor.process(conn, provider, mapped_user, response),
         {:ok, conn} <- Storage.store(conn, provider, user, result) do
      EmailAuthenticationHandler.handle_authenticated(conn, user)

      conn
      |> redirect_back(params)
    else
      {:error, :unauthenticated} ->
        Process.sleep(Enum.random(100..300//10))
        # Sleep for random amount to prevent timing attacks

        EmailAuthenticationHandler.handle_unauthenticated(conn, params)
    end
  end

  def delete(conn, params) do
    storage = Storage.current_storage(conn)

    with user when not is_nil(user) <- storage.current_user(conn) do
      conn
      |> storage.delete()
      |> redirect_back(params)
    else
      nil ->
        redirect_back(conn, params)
    end
  end

  @spec redirect_back(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirect_back(conn, params \\ %{}) do
    redirect_to =
      get_session(conn, :redirect_to) ||
        params["redirect_to"] ||
        "/"

    conn
    |> delete_session(:redirect_to)
    |> redirect(to: redirect_to)
  end
end
