defmodule KeenAuth.Processor do
  alias KeenAuth.AuthenticationController
  alias KeenAuth.Strategy

  @default_processor KeenAuth.Processor.Default

  @callback process(
              conn :: Plug.Conn.t(),
              provider :: atom(),
              mapped_user :: KeenAuth.User.t() | map(),
              response :: AuthenticationController.oauth_callback_response() | nil
            ) ::
              {:ok, Plug.Conn.t(), KeenAuth.User.t() | map(), AuthenticationController.oauth_callback_result() | nil} | Plug.Conn.t()

  @callback sign_out(conn :: Plug.Conn.t(), provider :: binary(), params :: map()) :: Plug.Conn.t()

  defmacro __using__(_params \\ nil) do
    quote do
      @behaviour unquote(__MODULE__)

      def process(conn, provider, mapped_user, oauth_response), do: unquote(__MODULE__).process(conn, provider, mapped_user, oauth_response)
      def sign_out(conn, provider, params), do: unquote(__MODULE__).sign_out(conn, provider, params)

      defoverridable unquote(__MODULE__)
    end
  end

  def process(conn, provider, mapped_user, oauth_response) do
    current_processor(conn, provider).process(conn, provider, mapped_user, oauth_response)
  end

  def sign_out(conn, provider, params) do
    current_processor(conn, provider).signout(conn, provider, params)
  end

  def current_processor(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_processor(provider)
  end

  def get_processor(config, provider) do
    Strategy.get_strategy(config, provider)[:processor] || @default_processor
  end
end
