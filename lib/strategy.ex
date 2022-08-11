defmodule KeenAuth.Strategy do
  alias KeenAuth.Config

  def get_strategies(config) do
    Config.get(config, :strategies)
  end

  def get_strategies!(config) do
    get_strategies(config) || Config.raise_error("No strategies found in config")
  end

  def get_strategy(config, provider) do
    get_strategies(config)[provider]
  end

  def get_strategy!(config, provider) do
    get_strategy(config, provider) || Config.raise_error("No provider configuration for #{inspect(provider)}")
  end

  def current_strategy(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_strategy(provider)
  end

  def current_strategy!(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_strategy!(provider)
  end
end
