defmodule KeenAuth.UserMappers.AzureAD do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(:aad, user) do
    %KeenAuth.User{
      id: user["sub"],
      username: user["preferred_username"],
      display_name: user["name"],
      email: user["preferred_username"]
    }
  end
end
