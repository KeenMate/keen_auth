defmodule KeenAuth.User do
  @keys [:id, :username, :display_name, :email]

  @enforce_keys @keys
  defstruct @keys

  @type t() :: %{
    id: binary() | pos_integer(),
    username: binary(),
    display_name: binary(),
    email: binary()
  }
end
