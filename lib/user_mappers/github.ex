defmodule KeenAuth.UserMappers.Github do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(:github, user) do
    user
  end
end
