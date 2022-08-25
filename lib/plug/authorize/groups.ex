defmodule KeenAuth.Plug.Authorize.Groups do
  @behaviour Plug

  import KeenAuth.Plug.Authorize

  def init(opts) do
    build_config(opts)
  end

  def call(conn, opts) do
    groups(conn, opts)
  end
end
