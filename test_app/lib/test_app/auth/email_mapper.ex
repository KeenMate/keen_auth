defmodule TestApp.Auth.EmailMapper do
  @moduledoc """
  Maps email authentication user data to KeenAuth.User struct.
  """

  use KeenAuth.Mapper

  @impl true
  def map(:email, user) do
    %KeenAuth.User{
      user_id: user["sub"],
      username: user["preferred_username"],
      display_name: user["name"],
      email: user["email"],
      roles: user["roles"] || [],
      permissions: [],
      groups: user["groups"] || []
    }
  end
end
