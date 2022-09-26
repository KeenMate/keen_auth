# KeenAuth

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `keen_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:keen_auth, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/keen_auth](https://hexdocs.pm/keen_auth).

## Required steps

Starting from a new project with ecto

1. Add `keen_auth` dependency
2. Add configuration to `config.exs`
    
    ```elixir
    common_auth_processor = DemoWeb.Auth.Processor
    
    config :keen_auth,
      # storage: KeenAuthDemoWeb.Auth.SessionStorage,
      strategies: [
        aad: [
          strategy: Assent.Strategy.AzureAD,
          mapper: KeenAuth.Mappers.AzureAD,
          processor: common_auth_processor,
          config: [
            tenant_id: "REPLACE_WITH_PROPPER_VALUE",
            client_id: "REPLACE_WITH_PROPPER_VALUE",
            client_secret: "REPLACE_WITH_PROPPER_VALUE",
            redirect_uri: "http://localhost:4000/aad/callback"
          ]
        ],
        github: [
          strategy: Assent.Strategy.Github,
          mapper: KeenAuth.Mappers.Github,
          processor: common_auth_processor,
          config: [
            client_id: "REPLACE_WITH_PROPPER_VALUE",
            client_secret: "REPLACE_WITH_PROPPER_VALUE",
            redirect_uri: "https://localhost:4000/auth/github/callback"
          ]
        ],
        facebook: [
          strategy: Assent.Strategy.Facebook,
          mapper: KeenAuth.Mappers.Facebook,
          processor: common_auth_processor,
          config: [
            client_id: "REPLACE_WITH_PROPPER_VALUE",
            client_secret: "REPLACE_WITH_PROPPER_VALUE",
            redirect_uri: "https://localhost:4000/auth/facebook/callback"
          ]
        ]
    ```
    
3. Replace cookie session storage with ETS
    1. Make sure to create session ETS table when the application starts
        
        ```elixir
        def start(_, _) do
        	children = [
        		# ...
        	]
        
        	create_session_table()
        
        	opts = [strategy: :one_for_one, name: Demo.Supervisor]
          Supervisor.start_link(children, opts)
        end
        
        defp create_session_table() do
          :ets.new(:session, [:named_table, :public, read_concurrency: true])
        end
        ```
        
    2. Reconfigure `@session_options` in `endpoint.ex` to ETS
        
        ```elixir
        @session_options [
          store: :ets,
          table: :session,
          key: "_test_key",
          signing_salt: "EdtoEWM7"
        ]
        ```
        
4. Modify router
    1. Add this line to the beginning of router
        
        ```elixir
        require KeenAuth
        ```
        
    2. Add following pipelines
        
        ```elixir
        pipeline :authentication do
          plug :fetch_session
          plug :put_root_layout, {KeenAuthDemoWeb.LayoutView, :root}
        end
        
        pipeline :authorization do
          plug :fetch_session
          plug KeenAuth.Plug.FetchUser
        end
        ```
        
    3. Add `/auth` subroute
        
        ```elixir
        scope "/auth" do
          pipe_through :authentication
        
          KeenAuth.authentication_routes()
        end
        ```
        
5. Enable HTTPS for development (as required by Facebook)
    1. `mix phx.gen.cert`
    2. Replace `http` configuration under Endpoint in `config/dev.exs` with `https`
        
        ```elixir
        https: [
          ip: {127, 0, 0, 1},
          port: 4000,
          cipher_suite: :strong,
          keyfile: "priv/cert/selfsigned_key.pem",
          certfile: "priv/cert/selfsigned.pem"
        ],
        ```
        

## Optional steps

- Add login buttons
    - Add `/sign-in` route to router
        
        ```elixir
        get "/sign-in", PageController, :sign_in
        ```
        
    - Add `sign_in` route to `PageController`
        
        ```elixir
        defmodule DemoWeb.PageController do
        	alias KeenAuth.Config
        	
        	def sign_in(conn, _params) do
        	  if Config.get_storage().current_user(conn) do
        	    redirect(conn, to: "/")
        	  else
        	    render(conn, "sign_in.html")
        	  end
        	end
        end
        ```
        
    - Add `sign_in.html.heex` template
        
        ```html
        <style>
        	.sign-in-options {
        			display: flex;
        			justify-content: center;
        			align-items: center;
        	}
        
        	.sign-in-options .option {
        			flex: 1;
        	}
        </style>
        
        <section class="row">
        	<article class="column">
        		<h2>Sign in options:</h2>
        
        		<div class="sign-in-options">
        			<div class="option">
        				<a href={Routes.authentication_path(@conn, :new, :aad, redirect_to: "/")}>
        					Azure
        				</a>
        			</div>
        			<div class="option">
        				<a href={Routes.authentication_path(@conn, :new, :github, redirect_to: "/")}>
        					Github
        				</a>
        			</div>
        			<div class="option">
        				<a href={Routes.authentication_path(@conn, :new, :facebook, redirect_to: "/")}>
        					Facebook
        				</a>
        			</div>
        		</div>
        	</article>
        </section>
        ```
        
        1. Create processor module (`DemoWeb.Auth.Processor`) implementing `KeenAuth.Processor` behavior
            
            ```elixir
            defmodule TestWeb.Auth.Processor do
              @behaviour KeenAuth.Processor
            
              import Plug.Conn, only: [put_session: 3]
            
              require Logger
            
              @impl true
              def process(conn, provider, response) do
                Logger.debug("Processing OAuth response for #{provider}", response: inspect(response))
            
                {:ok, put_session(conn, :oauth_response, response), response}
              end
            end
            ```
