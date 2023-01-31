defmodule KeenAuth.Mapper.Default do
  use KeenAuth.Mapper

  @impl true
  def map(_provider, user) do
    user
  end
end
