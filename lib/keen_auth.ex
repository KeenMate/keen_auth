defmodule KeenAuth do
  @moduledoc """
  ## Configuration

  ```
  config :keen_auth,
    auth_controller: MyAppWeb.AuthController,
    strategies: [
      azure_ad: [
        strategy: Assent.Strategy.Azure,
        config: [
          client_id: "REPLACE_WITH_CLIENT_ID",
          client_secret: "REPLACE_WITH_CLIENT_SECRET",
          redirect_uri: "http://localhost:4000/azure_ad/callback"
        ]
      ],
      github: [
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
        post "/callback", unquote(auth_controller), :callback
      end

      get "/delete", unquote(auth_controller), :delete
    end
  end
end
