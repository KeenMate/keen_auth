defmodule KeenAuth.Helpers.Roles do
  def normalize_role(role) when is_atom(role) do
    role
    |> Atom.to_string()
    |> normalize_role()
  end

  def normalize_role(role) when is_binary(role) do
    role
    |> String.downcase()
  end

  def has_all_roles(user_roles, required_roles) do
    Enum.all?(required_roles || [], &(&1 in (user_roles || [])))
  end

  def has_any_role(user_roles, required_roles) do
    Enum.any?(required_roles || [], &Enum.member?(user_roles || [], &1))
  end
end
