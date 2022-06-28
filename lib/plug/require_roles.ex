defmodule KeenAuth.Plug.RequireRoles do
  @behaviour Plug

  alias KeenAuth.Config
  alias KeenAuth.Helpers.Roles
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

    case roles do
      [] ->
        conn

      roles ->
        conn
        |> storage.get_roles()
        |> check_roles(op, roles)
        |> if do
          conn
        else
          handle_forbidden(conn, opts)
        end
    end
  end

  defp check_roles(current_roles, op, roles) do
    check_roles(current_roles, nil, op, roles)
  end

  defp check_roles(_user_roles, true, _op, []), do: true

  defp check_roles(_user_roles, _acc, _op, []), do: false

  defp check_roles(_user_roles, false, :and, _roles_to_check), do: false

  defp check_roles(user_roles, acc, :and, [role_to_check | other_roles_to_check])
       when acc in [nil, true] do
    check_roles(
      user_roles,
      Roles.normalize_role(role_to_check) in user_roles,
      :and,
      other_roles_to_check
    )
  end

  defp check_roles(_user_roles, true, :or, _roles_to_check), do: true

  defp check_roles(user_roles, acc, :or, [role_to_check | other_roles_to_check])
       when acc in [nil, false] do
    check_roles(
      user_roles,
      Roles.normalize_role(role_to_check) in user_roles,
      :or,
      other_roles_to_check
    )
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
