defmodule KeenAuth do
  @moduledoc """
  ## Configuration

  ```
  config :keen_auth,
    auth_controller: MyAppWeb.AuthController,
    strategies: [
      azure_ad: [
        token: MyAppWeb.AADToken,
        strategy: Assent.Strategy.Azure,
        config: [
          client_id: "REPLACE_WITH_CLIENT_ID",
          client_secret: "REPLACE_WITH_CLIENT_SECRET",
          redirect_uri: "http://localhost:4000/azure_ad/callback"
        ]
      ],
      github: [
        token: MyAppWeb.GithubToken,
        strategy: Assent.Strategy.Github,
        config: [
          client_id: "REPLACE_WITH_CLIENT_ID",
          client_secret: "REPLACE_WITH_CLIENT_SECRET",
          redirect_uri: "http://localhost:4000/github/callback"
        ]
      ]
    ]
  ```
  """

  defmacro authentication_routes() do
    auth_controller = Application.get_env(:keen_auth, :auth_controller, KeenAuth.AuthController)
    quote do
      scope "/:provider" do
        get "/new", unquote(auth_controller), :new
        get "/callback", unquote(auth_controller), :callback
        post "/callback", unquote(auth_controller), :callback
      end

      get "/delete", unquote(auth_controller), :delete
    end
  end

  @spec current_user(Plug.Conn.t()) :: KeenAuth.User.t() | map() | term()
  def current_user(conn) do
    conn.assigns[:current_user]
  end
end
