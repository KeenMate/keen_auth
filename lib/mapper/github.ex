defmodule KeenAuth.Mapper.Github do
  use KeenAuth.Mapper

  @impl true
  def map(:github, user) do
    %KeenAuth.User{
      user_id: Integer.to_string(user["sub"]),
      username: user["preferred_username"],
      display_name: user["name"],
      email: user["email"],
      roles: [],
      permissions: []
    }
  end
end
