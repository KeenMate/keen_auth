defmodule KeenAuth.UserMappers.Google do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(:google, user) do
    user
  end
end
