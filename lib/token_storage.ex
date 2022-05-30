defmodule KeenAuth.TokenStorage do
  use Agent

  @type tokens_map() :: %{
    access_token: binary(),
    refresh_token: binary(),
    id_token: binary()
  }

  def start_link(opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec store_tokens(binary(), tokens_map()) :: :ok
  def store_tokens(user_id, tokens) do
    Agent.update(__MODULE__, &Map.put(&1, user_id, tokens))
  end

  @spec get_tokens(binary()) :: tokens_map() | nil
  def get_tokens(user_id) do
    Agent.get(__MODULE__, &Map.get(&1, user_id))
  end
end
