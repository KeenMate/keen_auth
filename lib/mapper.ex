defmodule KeenAuth.Mapper do
  alias KeenAuth.User
  alias KeenAuth.Strategy

  @default_mapper KeenAuth.Mappers.Default

  @callback map(provider :: atom(), user :: map()) :: User.t()

  defmacro __using__(_params \\ nil) do
    quote do
      @behaviour unquote(__MODULE__)

      def map(provider, user), do: unquote(__MODULE__).map(provider, user)

      defoverridable unquote(__MODULE__)
    end
  end

  def current_mapper(conn, provider) do
    KeenAuth.Plug.fetch_config(conn)
    |> get_mapper(provider)
  end

  def get_mapper(config, provider) do
    Strategy.get_strategy(config, provider)[:mapper] || @default_mapper
  end
end
