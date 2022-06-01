defmodule KeenAuth.User do
  @keys [:id, :username, :display_name, :email]

  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
    id: binary(),
    username: binary(),
    display_name: binary(),
    email: binary()
  }
end
