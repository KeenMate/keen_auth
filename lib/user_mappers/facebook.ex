defmodule KeenAuth.UserMappers.Facebook do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(:facebook, user) do
    %KeenAuth.User{
      id: user["sub"],
      username: nil,
      display_name: user["name"],
      email: user["email"]
    }
  end
end
