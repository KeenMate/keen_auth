defmodule KeenAuth.Helpers.RedirectValidator do
  @moduledoc """
  Validates redirect URLs to prevent open redirect vulnerabilities.

  By default, only relative URLs (starting with `/`) are allowed. You can configure
  a custom validator callback in your application config:

      config :keen_auth,
        redirect_validator: &MyApp.Auth.validate_redirect/2

  ## Callback Signature

  The callback receives the redirect URL and the connection, and should return:
  - `{:ok, url}` - URL is valid, use this URL (allows transformation)
  - `:error` - URL is invalid, will fall back to "/"

  ## Examples

  ### Relative paths only (default)

      config :keen_auth,
        redirect_validator: &KeenAuth.Helpers.RedirectValidator.relative_only/2

  ### Database-backed allowlist

      def validate_redirect(url, _conn) do
        uri = URI.parse(url)
        if AllowedDomains.exists?(uri.host) do
          {:ok, url}
        else
          :error
        end
      end

  ### Allow specific domains

      def validate_redirect(url, _conn) do
        uri = URI.parse(url)
        allowed = ["myapp.com", "app.myapp.com", nil]  # nil = relative URL
        if uri.host in allowed, do: {:ok, url}, else: :error
      end
  """

  require KeenAuth.Logger, as: Log

  @max_url_length 2048

  @doc """
  Validates a redirect URL using the configured validator.

  Returns the validated URL or "/" if validation fails or URL is nil.
  """
  @spec validate(binary() | nil, Plug.Conn.t()) :: binary()
  def validate(nil, _conn), do: "/"

  def validate(url, _conn) when byte_size(url) > @max_url_length do
    Log.warn(:security, "Rejected redirect URL exceeding max length", length: byte_size(url))
    "/"
  end

  def validate(url, conn) do
    validator = get_validator(conn)

    case validator.(url, conn) do
      {:ok, validated_url} ->
        Log.debug(:security, "Validated redirect URL", url: validated_url)
        validated_url

      :error ->
        Log.warn(:security, "Rejected invalid redirect URL", url: url)
        "/"
    end
  end

  @doc """
  Default validator - only allows relative URLs starting with "/".

  Rejects URLs with:
  - Protocol-relative URLs (//example.com)
  - Absolute URLs (https://example.com)
  - URLs with encoded characters that could bypass validation
  """
  @spec relative_only(binary(), Plug.Conn.t()) :: {:ok, binary()} | :error
  def relative_only(url, _conn) do
    cond do
      # Must start with single /
      not String.starts_with?(url, "/") -> :error
      # Reject protocol-relative URLs (//example.com)
      String.starts_with?(url, "//") -> :error
      # Reject encoded slashes that could bypass validation
      String.contains?(url, "%2f") or String.contains?(url, "%2F") -> :error
      # Reject backslashes (IE compatibility issue)
      String.contains?(url, "\\") -> :error
      # Reject null bytes
      String.contains?(url, "\0") -> :error
      true -> {:ok, url}
    end
  end

  defp get_validator(conn) do
    config = KeenAuth.Plug.fetch_config(conn)

    KeenAuth.Config.get(config, :redirect_validator, &relative_only/2)
  end
end
