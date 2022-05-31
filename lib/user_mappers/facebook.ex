defmodule KeenAuth.UserMappers.Facebook do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(:facebook, user) do
    user
  end
end
