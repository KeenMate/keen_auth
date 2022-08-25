defmodule KeenAuth.Mapper.AzureAD do
  @behaviour KeenAuth.Mapper

  @impl true
  def map(:aad, user) do
    %KeenAuth.User{
      user_id: user["sub"],
      username: user["preferred_username"],
      display_name: user["name"],
      email: user["preferred_username"],
      roles: user["roles"] || [],
      permissions: []
    }
  end
end
