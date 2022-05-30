defmodule KeenAuth.UserProcessor do
  @callback process(conn :: Plug.Conn.t())
end
