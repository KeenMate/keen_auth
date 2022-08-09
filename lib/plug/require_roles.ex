defmodule KeenAuth.Plug.RequireRoles do
  @behaviour Plug

  import KeenAuth.Helpers.Roles

  alias KeenAuth.Config
  alias Plug.Conn
  alias Phoenix.Controller

  def init(opts) do
    [
      storage: Config.get_storage(),
      operator: :and,
      roles: []
    ]
    |> Keyword.merge(opts)
  end

  def call(conn, opts) do
    storage = opts[:storage]
    roles = opts[:roles]
    op = opts[:op]

    conn
    |> storage.current_user()
    |> check_user_roles(op, roles)
    |> if do
      conn
    else
      handle_forbidden(conn, opts)
    end
  end

  defp check_user_roles(current_user, op, roles) do
    check_roles(current_user.roles, op, roles)
  end

  defp check_roles(current_roles, op, required_roles) do
    case op do
      :or -> has_any_role(current_roles, required_roles)
      :and -> has_all_roles(current_roles, required_roles)
    end
  end

  defp handle_forbidden(conn, opts) do
    case opts[:handler] do
      {mod, fun} ->
        apply(mod, fun, [conn])
      nil ->
        conn
        |> Conn.put_status(403)
        |> Controller.put_flash(:error, "You are not allowed to view this content")
        |> Conn.halt()
    end
  end
end
