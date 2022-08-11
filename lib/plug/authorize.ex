defmodule KeenAuth.Plug.Authorize do
  require Logger

  import KeenAuth.Helpers.Roles

  alias KeenAuth.Config

  @default_operation :and
  @default_handler KeenAuth.Plug.AuthorizationErrorHandler

  def roles(conn, opts) when is_map(opts) do
    ensure(conn, :roles, opts)
  end

  def roles(conn, opts) when is_list(opts) do
    config = build_config(opts)

    ensure(conn, :roles, config)
  end

  def permissions(conn, opts) when is_map(opts) do
    ensure(conn, :permissions, opts)
  end

  def permissions(conn, opts) when is_list(opts) do
    config = build_config(opts)

    ensure(conn, :permissions, config)
  end

  def build_config(opts) do
    %{
      storage: Keyword.get(opts, :storage, Config.get_storage()),
      actions: Keyword.get(opts, :only) |> allowed_actions(),
      roles: Keyword.get(opts, :roles, []) |> Enum.map(&normalize_role/1),
      permissions: Keyword.get(opts, :permissions, []) |> Enum.map(&normalize_role/1),
      operation: Keyword.get(opts, :op, @default_operation),
      handler: Keyword.get(opts, :error_handler, @default_handler)
    }
  end

  defp ensure(conn, :permissions, %{storage: storage, actions: actions, permissions: permissions, operation: operation, handler: handler}) do
    if is_nil(actions) or conn.private.phoenix_action in actions do
      allowed = ensure_user_permissions(storage.current_user(conn), permissions, operation)

      conn
      |> resolve_authorization(allowed, handler)
    else
      conn
    end
  end

  defp ensure(conn, :roles, %{storage: storage, actions: actions, roles: roles, operation: operation, handler: handler}) do
    if is_nil(actions) or conn.private.phoenix_action in actions do
      allowed = ensure_user_roles(storage.current_user(conn), roles, operation)

      conn
      |> resolve_authorization(allowed, handler)
    else
      conn
    end
  end

  defp ensure_user_permissions(nil, _, _), do: nil

  defp ensure_user_permissions(%{permissions: current_permissions}, required_permissions, :or) do
    current_permissions
    |> Enum.map(&normalize_role/1)
    |> has_any_role(required_permissions)
  end

  defp ensure_user_permissions(%{permissions: current_permissions}, required_permissions, :and) do
    current_permissions
    |> Enum.map(&normalize_role/1)
    |> has_all_roles(required_permissions)
  end

  defp ensure_user_roles(nil, _, _), do: nil

  defp ensure_user_roles(%{roles: current_roles}, required_roles, :or) do
    current_roles
    |> Enum.map(&normalize_role/1)
    |> has_any_role(required_roles)
  end

  defp ensure_user_roles(%{roles: current_roles}, required_roles, :and) do
    current_roles
    |> Enum.map(&normalize_role/1)
    |> has_all_roles(required_roles)
  end

  defp allowed_actions(nil), do: nil
  defp allowed_actions(action) when is_atom(action), do: [action]
  defp allowed_actions(actions) when is_list(actions), do: actions

  # Forbidden handler
  defp resolve_authorization(conn, false, handler) do
    conn
    |> handler.call(:unauthorized)
    |> Plug.Conn.halt()
  end

  # Unauthorized handler
  defp resolve_authorization(conn, nil, handler) do
    conn
    |> handler.call(:unauthorized)
    |> Plug.Conn.halt()
  end

  defp resolve_authorization(conn, true, _), do: conn
end
