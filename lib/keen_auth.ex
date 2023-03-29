defmodule KeenAuth do
  @moduledoc """
  ## Configuration

  ```
  config :keen_auth,
    auth_controller: MyAppWeb.AuthenticationController,
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
    # TODO since `auth_controller` cannot be retrieved based on OTP app configuration, route to concrete controller in `AuthenticationController` and move default implementation elsewhere
    auth_controller = Application.get_env(:keen_auth, :auth_controller, KeenAuth.AuthenticationController)
    email_enabled = Application.get_env(:keen_auth, :email_enabled, false)

    email_block =
      if email_enabled do
        email_auth_controller = Application.get_env(:keen_auth, :email_auth_controller, KeenAuth.EmailAuthenticationController)

        quote do
          scope "/email" do
            post("/new", unquote(email_auth_controller), :new)
          end
        end
      else
        nil
      end

    quote do
      unquote(email_block)

      scope "/:provider" do
        get("/new", unquote(auth_controller), :new)
        get("/callback", unquote(auth_controller), :callback)
        post("/callback", unquote(auth_controller), :callback)
        get("/delete", unquote(auth_controller), :delete)
      end

      get("/delete", unquote(auth_controller), :delete)
    end
  end

  @spec current_user(Plug.Conn.t()) :: KeenAuth.User.t() | map() | term()
  def current_user(conn) do
    conn.assigns[:current_user]
  end
end
