defmodule KeenAuth.Mapper.AzureAD do
  @moduledoc """
  Mapper for Azure AD / Microsoft Entra ID users.

  Maps the user claims from Azure AD to a `KeenAuth.User` struct.
  Supports both `:aad` and `:azure_ad` provider atoms.
  """

  use KeenAuth.Mapper

  @impl true
  def map(provider, user) when provider in [:aad, :azure_ad] do
    %KeenAuth.User{
      user_id: user["sub"],
      username: user["preferred_username"],
      display_name: user["name"],
      email: user["preferred_username"],
      roles: user["roles"] || [],
      permissions: [],
      groups: user["groups"] || []
    }
  end
end
