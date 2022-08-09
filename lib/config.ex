defmodule KeenAuth.Config do
  @default_user_mapper KeenAuth.UserMappers.Default
  @default_processor KeenAuth.Processors.Default

  @spec get_storage(atom()) :: module()
  def get_storage(provider \\ nil) do
    get_strategy_config(provider)[:storage]
    || Application.get_env(:keen_auth, :storage)
    || KeenAuth.Storage.Session
  end

  def get_token(provider) do
    get_strategy_config(provider)[:token] || KeenAuth.Token
  end

  @spec get_strategy_config(atom()) :: keyword() | nil
  def get_strategy_config(provider) do
    Application.get_env(:keen_auth, :strategies)[provider]
  end

  @spec get_strategy_config!(atom()) :: keyword()
  def get_strategy_config!(provider) do
    Application.get_env(:keen_auth, :strategies)[provider] || raise "No provider configuration for #{provider}"
  end

  @spec get_user_mapper(atom()) :: module()
  def get_user_mapper(provider) do
    get_strategy_config(provider)[:mapper] || @default_user_mapper
  end

  @spec get_processor(atom()) :: module()
  def get_processor(provider) do
    get_strategy_config(provider)[:processor] || @default_processor
  end

  # @spec get_key_from_provider_config(atom(), atom()) :: any
  # def get_key_from_provider_config(provider, key) do
  #   strategy = get_strategy!(provider)

  #   strategy[key]
  # end
end
