defmodule KeenAuth.Plug.Authorize do
  require Logger

  @default_operation :and
  @default_handler KeenAuth.Plug.AuthorizationErrorHandler

  def groups(conn, opts) when is_map(opts) do
    check(conn, opts, :groups)
  end

  def groups(conn, opts) when is_list(opts) do
    config = build_config(opts)

    check(conn, config, :groups)
  end

  def roles(conn, opts) when is_map(opts) do
    check(conn, opts, :roles)
  end

  def roles(conn, opts) when is_list(opts) do
    config = build_config(opts)

    check(conn, config, :roles)
  end

  def permissions(conn, opts) when is_map(opts) do
    check(conn, opts, :permissions)
  end

  def permissions(conn, opts) when is_list(opts) do
    config = build_config(opts)

    check(conn, config, :permissions)
  end

  def build_config(opts) do
    %{
      actions: Keyword.get(opts, :only) |> allowed_actions(),
      required_values: Keyword.fetch!(opts, :required_values) |> Enum.map(&normalize_value/1),
      operation: Keyword.get(opts, :op, @default_operation),
      handler: Keyword.get(opts, :error_handler, @default_handler)
    }
  end

  defp check(conn, config, key) do
    if is_nil(config.actions) or conn.private.phoenix_action in config.actions do
      current_user = KeenAuth.current_user(conn)
      allowed = is_allowed(current_user, config, key)

      resolve_authorization(conn, allowed, config.handler)
    else
      conn
    end
  end

  # Unauthenticated user not allowed
  defp is_allowed(nil, _, _), do: false

  defp is_allowed(current_user, config, key) do
    current_user
    |> fetch_user_values(key)
    |> Enum.map(&normalize_value/1)
    |> check_user_values(config.required_values, config.operation)
  end

  defp check_user_values(_, nil, _), do: false

  defp check_user_values(user_values, required_values, :or) do
    user_values
    |> has_any_value(required_values)
  end

  defp check_user_values(user_values, required_values, :and) do
    user_values
    |> has_all_values(required_values)
  end

  defp fetch_user_values(user, :permissions), do: user.permissions
  defp fetch_user_values(user, :roles), do: user.roles
  defp fetch_user_values(user, :groups), do: user.groups

  defp allowed_actions(nil), do: nil
  defp allowed_actions(action) when is_atom(action), do: [action]
  defp allowed_actions(actions) when is_list(actions), do: actions

  # Forbidden handler
  defp resolve_authorization(conn, false, handler) do
    conn
    |> handler.call(:unauthorized)
    |> Plug.Conn.halt()
  end

  defp resolve_authorization(conn, true, _), do: conn

  defp normalize_value(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_value()
  end

  defp normalize_value(value) when is_binary(value) do
    value
    |> String.downcase()
  end

  defp has_all_values(user_values, required_values) do
    Enum.all?(required_values || [], &(&1 in (user_values || [])))
  end

  defp has_any_value(user_values, required_values) do
    Enum.any?(required_values || [], &Enum.member?(user_values || [], &1))
  end
end
