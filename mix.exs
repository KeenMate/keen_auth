defmodule KeenAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :keen_auth,
      version: "0.2.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "KeenAuth",
      source_url: "https://github.com/KeenMate/keen_auth.git"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:openid_connect, "~> 0.2.2"},
      {:plug, "~> 1.10"}
    ]
  end

  defp description() do
    "Library faciliating OpenID authentication flow throughout Phoenix application(s)"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "keen_auth",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/KeenMate/keen_auth"}
    ]
  end
end
