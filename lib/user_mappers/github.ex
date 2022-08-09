defmodule KeenAuth.UserMappers.Github do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(:github, user) do
    %KeenAuth.User{
      id: Integer.to_string(user["sub"]),
      username: user["preferred_username"],
      display_name: user["name"],
      email: user["email"],
      roles: [],
      permissions: []
    }
  end
end
