defmodule KeenAuth.Session do
  @callback new(conn :: Plug.Conn.t(), user :: map(), token :: binary()) :: Plug.Conn.t()
  @callback current_user(conn :: Plug.Conn.t()) :: map()
  @callback access_token(conn :: Plug.Conn.t()) :: binary()
  @callback delete(conn :: Plug.Conn.t()) :: Plug.Conn.t()

  import Plug.Conn, only: [put_session: 3, delete_session: 2, get_session: 2]

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour unquote(__MODULE__)

      def new(conn, user, token), do: unquote(__MODULE__).new(conn, user, token)
      def current_user(conn), do: unquote(__MODULE__).current_user(conn)
      def access_token(conn), do: unquote(__MODULE__).access_token(conn)
      def delete(conn), do: unquote(__MODULE__).delete(conn)

      defoverridable [new: 3, current_user: 1, access_token: 1, delete: 1]
    end
  end

  def new(conn, user, token) do
    conn
    |> put_session(:current_user, user)
    |> put_session(:access_token, token)
  end

  def current_user(conn) do
    get_session(conn, :current_user)
  end

  def access_token(conn) do
    get_session(conn, :access_token)
  end

  def delete(conn) do
    conn
    |> delete_session(:current_user)
    |> delete_session(:access_token)
  end

end