defmodule KeenAuth.Processor do
  alias KeenAuth.AuthController
  alias KeenAuth.Strategy

  @default_processor KeenAuth.Processors.Default

  @callback process(conn :: Plug.Conn.t(), provider :: atom(), response :: AuthController.oauth_callback_response()) ::
              {:ok, Plug.Conn.t(), AuthController.oauth_callback_result()} | Plug.Conn.t()

  def process(conn, provider, oauth_response) do
    current_processor(conn, provider).process(conn, provider, oauth_response)
  end

  def current_processor(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_processor(provider)
  end

  def get_processor(config, provider) do
    Strategy.get_strategy(config, provider)[:processor] || @default_processor
  end
end
