defmodule KeenAuth.UserMappers.Common do
  @behaviour KeenAuth.UserMapper

  @impl true
  def map(_provider, user) do
    user
  end
end
