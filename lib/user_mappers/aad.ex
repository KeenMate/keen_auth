defmodule KeenAuth.UserMappers.AzureAD do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(:aad, user) do
    user
  end
end
