defmodule KeenAuth.Helpers.InputValidator do
  @moduledoc """
  Validates input parameters to prevent abuse and ensure security.

  This module provides validation for common input fields like provider names
  and redirect URLs. It helps prevent denial of service through oversized inputs
  and other input-based attacks.
  """

  @max_provider_length 64
  @max_redirect_length 2048

  @doc """
  Validates a provider name.

  Returns `{:ok, provider}` if valid, or `{:error, reason}` if invalid.

  Validation rules:
  - Must not exceed #{@max_provider_length} characters
  - Must only contain alphanumeric characters, hyphens, and underscores
  """
  @spec validate_provider(binary()) :: {:ok, binary()} | {:error, :invalid_provider}
  def validate_provider(provider) when is_binary(provider) do
    cond do
      byte_size(provider) > @max_provider_length ->
        {:error, :invalid_provider}

      not Regex.match?(~r/^[a-zA-Z0-9_-]+$/, provider) ->
        {:error, :invalid_provider}

      true ->
        {:ok, provider}
    end
  end

  def validate_provider(_), do: {:error, :invalid_provider}

  @doc """
  Validates a redirect URL length.

  Returns `{:ok, url}` if valid, or `{:error, reason}` if too long.
  """
  @spec validate_redirect_length(binary() | nil) :: {:ok, binary() | nil} | {:error, :redirect_too_long}
  def validate_redirect_length(nil), do: {:ok, nil}

  def validate_redirect_length(url) when is_binary(url) do
    if byte_size(url) > @max_redirect_length do
      {:error, :redirect_too_long}
    else
      {:ok, url}
    end
  end

  def validate_redirect_length(_), do: {:ok, nil}
end
