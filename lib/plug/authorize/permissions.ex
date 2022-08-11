defmodule KeenAuth.Plug.Authorize.Permissions do
  @behaviour Plug

  import KeenAuth.Plug.Authorize

  def init(opts) do
    build_config(opts)
  end

  def call(conn, opts) do
    permissions(conn, opts)
  end
end
