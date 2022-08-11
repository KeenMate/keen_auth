defmodule KeenAuth.Plug.Authorize.Roles do
  @behaviour Plug

  import KeenAuth.Plug.Authorize

  def init(opts) do
    build_config(opts)
  end

  def call(conn, opts) do
    roles(conn, opts)
  end
end
