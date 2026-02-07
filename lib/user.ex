defmodule KeenAuth.User do
  @moduledoc """
  Represents an authenticated user in KeenAuth.

  This struct is the normalized representation of a user after being processed
  by a mapper. All OAuth providers are mapped to this common structure.

  ## Fields

  - `:user_id` - Unique identifier from the OAuth provider
  - `:username` - Username (may be nil for some providers)
  - `:display_name` - Human-readable name
  - `:email` - Email address
  - `:roles` - List of role strings (populated by processor)
  - `:permissions` - List of permission strings (populated by processor)
  - `:groups` - List of group strings (populated by processor)

  ## Example

      %KeenAuth.User{
        user_id: "abc123",
        username: "jdoe",
        display_name: "John Doe",
        email: "john@example.com",
        roles: ["admin"],
        permissions: ["read", "write"],
        groups: ["engineering"]
      }
  """

  @keys [:user_id, :username, :display_name, :email, :roles, :permissions, :groups]

  defstruct @keys

  @type t() :: %__MODULE__{
          user_id: binary(),
          username: binary() | nil,
          display_name: binary(),
          email: binary(),
          roles: list(binary()),
          permissions: list(binary()),
          groups: list(binary())
        }

  @doc """
  Creates a new User struct from a map of attributes.

  ## Example

      KeenAuth.User.new(%{
        user_id: "123",
        email: "user@example.com",
        display_name: "User"
      })
  """
  @spec new(map()) :: t()
  def new(params \\ %{}) do
    struct(__MODULE__, atomize_keys(params))
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
  rescue
    ArgumentError -> map
  end
end
