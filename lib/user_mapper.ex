defmodule KeenAuth.UserMapper do
  alias KeenAuth.User

  @callback map(provider :: binary(), user :: map()) :: User.t()

  def map(_provider, user) do
    user
  end
end
