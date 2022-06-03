defmodule KeenAuth.Config do
  def get_storage() do
    Application.get_env(:keen_auth, :storage) || KeenAuth.Storage.Session
  end

  def get_storage(provider) do
    get_strategy_config(provider)[:storage] || KeenAuth.Storage.Session
  end

  def get_token(provider) do
    get_strategy_config(provider)[:token] || KeenAuth.Token
  end

  def get_strategy_config(provider) do
    Application.get_env(:keen_auth, :strategies)[provider]
  end
end
