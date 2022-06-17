defmodule KeenAuth.User do
  alias Ecto.Changeset

  @keys [:id, :username, :display_name, :email]

  # @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
    id: binary(),
    username: binary(),
    display_name: binary(),
    email: binary()
  }

  @changeset_fields %{
    id: :string,
    username: :string,
    display_name: :string,
    email: :string
  }

  def new(params \\ %{}) do
    {%__MODULE__{}, @changeset_fields}
    |> Changeset.cast(params, @keys)
  end
end
