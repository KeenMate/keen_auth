defmodule KeenAuth.Helpers.Binary do
  def to_atom(bin) when is_binary(bin) do
    String.to_existing_atom(bin)
  end

  def to_atom(atom) when is_atom(atom) do
    atom
  end
end
