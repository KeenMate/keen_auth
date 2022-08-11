defmodule KeenAuth.Mapper.Default do
  @behaviour KeenAuth.Mapper

  @impl true
  def map(_provider, user) do
    user
  end
end
