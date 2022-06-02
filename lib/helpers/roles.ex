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

end
