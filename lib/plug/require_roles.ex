defmodule KeenAuth.Plug.RequireRoles do
  @behaviour Plug

  alias KeenAuth.Config
  alias KeenAuth.Helpers.Roles
  alias Plug.Conn

  def init(opts) do
    %{
      storage: Config.get_storage(),
      operator: opts[:operator] || :and,
      roles: opts[:roles] || []
    }
  end

  def call(conn, %{roles: []}), do: conn

  def call(conn, opts) do
    %{
      storage: storage,
      roles: roles,
      operator: op
    } = opts

    conn
    |> storage.get_roles()
    |> check_roles(op, roles)
    |> if do
      conn
    else
      set_forbidden(conn)
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

  defp set_forbidden(conn) do
    Conn.put_status(conn, 403)
  end
end
