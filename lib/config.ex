defmodule KeenAuth.Config do
  def get_storage() do
    Application.get_env(:keen_auth, :storage) || KeenAuth.Storage.Session
  end

  def get_token(provider) do
    Application.get_env(:keen_auth, :strategies)[provider][:token] || __MODULE__
  end
end
