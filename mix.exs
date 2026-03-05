defmodule KeenAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :keen_auth,
      version: "1.0.2",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      name: "KeenAuth",
      source_url: "https://github.com/KeenMate/keen_auth",
      homepage_url: "https://hexdocs.pm/keen_auth"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "SECURITY.md",
        "LICENSE"
      ],
      before_closing_body_tag: &before_closing_body_tag/1,
      groups_for_modules: [
        Core: [
          KeenAuth,
          KeenAuth.User,
          KeenAuth.Config
        ],
        Pipeline: [
          KeenAuth.Mapper,
          KeenAuth.Processor,
          KeenAuth.Storage,
          KeenAuth.Strategy
        ],
        "Built-in Mappers": [
          KeenAuth.Mapper.Default,
          KeenAuth.Mapper.AzureAD,
          KeenAuth.Mapper.Github,
          KeenAuth.Mapper.Facebook
        ],
        "Built-in Storage": [
          KeenAuth.Storage.Session
        ],
        Plugs: [
          KeenAuth.Plug,
          KeenAuth.Plug.FetchUser,
          KeenAuth.Plug.RequireAuthenticated,
          KeenAuth.Plug.AuthSession
        ],
        Authorization: [
          KeenAuth.Plug.Authorize,
          KeenAuth.Plug.Authorize.Roles,
          KeenAuth.Plug.Authorize.Groups,
          KeenAuth.Plug.Authorize.Permissions,
          KeenAuth.Plug.AuthorizationErrorHandler
        ],
        Controllers: [
          KeenAuth.AuthenticationController,
          KeenAuth.EmailAuthenticationController,
          KeenAuth.EmailAuthenticationHandler
        ],
        Helpers: [
          KeenAuth.Helpers.RedirectValidator,
          KeenAuth.Helpers.InputValidator,
          KeenAuth.Helpers.RequestHelpers,
          KeenAuth.Helpers.Binary
        ],
        Utilities: [
          KeenAuth.Logger,
          KeenAuth.Token,
          KeenAuth.Token.JWT,
          KeenAuth.Processor.Default
        ]
      ],
      nest_modules_by_prefix: [
        KeenAuth.Plug.Authorize,
        KeenAuth.Mapper,
        KeenAuth.Helpers
      ]
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false, theme: "default" });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          graphEl.classList.add("mermaid-graph");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg}) => {
            graphEl.innerHTML = svg;
            preEl.replaceWith(graphEl);
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:phoenix, ">= 1.6.7"},
      {:phoenix_pubsub, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:assent, "~> 0.3.0"},
      {:joken, "~> 2.6"},
      # HTTP client for Assent OAuth requests (handles SSL properly)
      {:req, "~> 0.5"}
    ]
  end

  defp description() do
    "Library faciliating OpenID authentication flow throughout Phoenix application(s)"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "keen_auth",
      # organization: "keenmate",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/KeenMate/keen_auth"}
    ]
  end
end
