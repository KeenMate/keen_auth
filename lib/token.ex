defmodule KeenAuth.Token do
  alias KeenAuth.Strategy

  @default_token KeenAuth.Token.JWT

  def get_token(config, provider) do
    Strategy.get_strategy(config, provider)[:token] || @default_token
  end

  def current_token(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_token(provider)
  end
end
