defmodule KeenAuth.Mapper.Facebook do
  @behaviour KeenAuth.Mapper

  @impl true
  def map(:facebook, user) do
    %KeenAuth.User{
      user_id: user["sub"],
      username: nil,
      display_name: user["name"],
      email: user["email"],
      roles: [],
      permissions: []
    }
  end
end
