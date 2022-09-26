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

  def process(conn, provider, mapped_user, oauth_response) do
    current_processor(conn, provider).process(conn, provider, mapped_user, oauth_response)
  end

  def current_processor(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_processor(provider)
  end

  def get_processor(config, provider) do
    Strategy.get_strategy(config, provider)[:processor] || @default_processor
  end
end
