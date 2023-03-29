defmodule KeenAuth.Storage do
  alias KeenAuth.AuthenticationController
  alias KeenAuth.Config

  @default_storage KeenAuth.Storage.Session

  @callback store(
              conn :: Plug.Conn.t(),
              provider :: atom(),
              mapped_user :: KeenAuth.User.t() | map(),
              oauth_response :: AuthenticationController.oauth_callback_response() | nil
            ) :: {:ok, Plug.Conn.t()}
  @callback current_user(conn :: Plug.Conn.t()) :: any() | nil
  @callback authenticated?(conn :: Plug.Conn.t()) :: boolean()
  @callback get_access_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback get_id_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback get_refresh_token(conn :: Plug.Conn.t()) :: binary() | nil
  @callback get_provider(conn :: Plug.Conn.t()) :: binary() | nil
  @callback delete(conn :: Plug.Conn.t()) :: Plug.Conn.t()
  @callback put_provider(conn :: Plug.Conn.t(), provider :: atom()) :: Plug.Conn.t()
  @callback put_tokens(conn :: Plug.Conn.t(), provider :: atom(), AuthenticationController.tokens_map()) :: Plug.Conn.t()
  @callback put_current_user(conn :: Plug.Conn.t(), provider :: atom(), KeenAuth.User.t() | map()) :: Plug.Conn.t()

  defmacro __using__(_params \\ nil) do
    quote do
      @behaviour unquote(__MODULE__)

      def process(conn, provider, mapped_user, oauth_response), do: unquote(__MODULE__).process(conn, provider, mapped_user, oauth_response)
      def store(conn, provider, mapped_user, oauth_response), do: unquote(__MODULE__).store(conn, provider, mapped_user, oauth_response)
      def current_user(conn), do: unquote(__MODULE__).current_user(conn)
      def authenticated?(conn), do: unquote(__MODULE__).authenticated?(conn)
      def authenticated?(conn), do: unquote(__MODULE__).authenticated?(conn)
      def get_access_token(conn), do: unquote(__MODULE__).get_access_token(conn)
      def get_id_token(conn), do: unquote(__MODULE__).get_id_token(conn)
      def get_refresh_token(conn), do: unquote(__MODULE__).get_refresh_token(conn)
      def get_provider(conn), do: unquote(__MODULE__).get_provider(conn)
      def delete(conn), do: unquote(__MODULE__).delete(conn)
      def put_provider(conn, provider), do: unquote(__MODULE__).put_provider(conn, provider)
      def put_tokens(conn, provider, tokens), do: unquote(__MODULE__).put_tokens(conn, provider, tokens)
      def put_current_user(conn, provider, user), do: unquote(__MODULE__).put_current_user(conn, provider, user)

      defoverridable unquote(__MODULE__)
    end
  end

  def store(conn, provider, mapped_user, oauth_response) do
    current_storage(conn).store(conn, provider, mapped_user, oauth_response)
  end

  def current_user(conn) do
    current_storage(conn).current_user(conn)
  end

  def authenticated?(conn) do
    current_storage(conn).authenticated?(conn)
  end

  def get_access_token(conn) do
    current_storage(conn).get_access_token(conn)
  end

  def get_id_token(conn) do
    current_storage(conn).get_id_token(conn)
  end

  def get_refresh_token(conn) do
    current_storage(conn).get_refresh_token(conn)
  end

  def get_provider(conn) do
    current_storage(conn).get_provider(conn)
  end

  def delete(conn) do
    current_storage(conn).delete(conn)
  end

  def put_provider(conn, provider) do
    current_storage(conn).put_provider(conn, provider)
  end

  def put_tokens(conn, provider, tokens) do
    current_storage(conn).put_tokens(conn, provider, tokens)
  end

  def put_current_user(conn, provider, user) do
    current_storage(conn).put_current_user(conn, provider, user)
  end

  def current_storage(conn) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_storage()
  end

  def get_storage(config) do
    Config.get(config, :storage, @default_storage)
  end
end
