defmodule KeenAuth.User do
  alias Ecto.Changeset

  @keys [:id, :username, :display_name, :email, :roles, :permissions]

  # @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
    id: binary(),
    username: binary() | nil,
    display_name: binary(),
    email: binary(),
    roles: list(binary()),
    permissions: list(binary())
  }

  @changeset_fields %{
    id: :string,
    username: :string,
    display_name: :string,
    email: :string,
    roles: {:array, :string},
    permissions: {:array, :string}
  }

  def new(params \\ %{}) do
    {%__MODULE__{}, @changeset_fields}
    |> Changeset.cast(params, @keys)
  end
end
