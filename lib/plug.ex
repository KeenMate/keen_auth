defmodule KeenAuth.Plug do
  @moduledoc """
  Main plug that stores KeenAuth configuration in the connection.

  This plug must be included in your pipeline before any KeenAuth functionality
  can be used. It stores the configuration in the connection's private data,
  making it accessible to controllers and other plugs.

  ## Usage

  Add the plug to your router pipeline:

      pipeline :authentication do
        plug KeenAuth.Plug, otp_app: :my_app
      end

      scope "/auth" do
        pipe_through [:browser, :authentication]
        KeenAuth.authentication_routes()
      end

  ## Configuration

  The plug accepts any configuration options that will be merged with your
  application's `:keen_auth` configuration. Common options:

  - `:otp_app` - The OTP application name where configuration is stored
  - `:strategies` - List of authentication strategies (usually in app config)
  - `:storage` - Custom storage module (defaults to session storage)
  """

  @behaviour Plug

  alias Plug.Conn
  alias KeenAuth.Config

  @private_config_key :keen_auth_config

  def init(config), do: config

  def call(conn, config) do
    put_config(conn, config)
  end

  @doc """
  Put the provided config as a private key in the connection.
  """
  @spec put_config(Conn.t(), Config.t()) :: Conn.t()
  def put_config(conn, config) do
    Conn.put_private(conn, @private_config_key, config)
  end

  @doc """
  Fetch configuration from the private key in the connection.

  It'll raise an error if configuration hasn't been set as a private key.
  """
  @spec fetch_config(Conn.t()) :: Config.t()
  def fetch_config(%{private: private}) do
    private[@private_config_key] || no_config_error!()
  end

  @spec no_config_error!() :: no_return()
  defp no_config_error!,
    do:
      Config.raise_error(
        "KeenAuth configuration not found in connection. Please use a KeenAuth plug that puts the KeenAuth configuration in the plug connection."
      )
end
